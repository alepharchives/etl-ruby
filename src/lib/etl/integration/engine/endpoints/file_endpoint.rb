# #!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module Endpoints

                # An endpoint for an file system entry (e.g. file, symlinked file, etc).
                class FileEndpoint < Endpoint

                    def initialize(endpoint_uri, execution_context)
                        super(endpoint_uri, execution_context)
                        @last_position = 0
                    end

                    def unmarshal()
                        validate_file_path(@endpoint_uri)
                        begin
                            file = File.open(full_path(), 'r')
                            file.seek(@last_position)
                            return nil if file.eof?
                            result = file.gets()
                            @last_position = file.pos()
                            exchange = build_outbound_exchange(result)
                            return exchange
                        rescue IOError => ex
                            _debug("Unable to unmarshal from file #{full_path()}: '#{ex.message}'", ex)
                            raise()
                        ensure
                            file.close() unless file.nil?
                        end
                    end

                    def reset()
                        @last_position = 0
                    end

                    # Marshalls the supplied exchange to this endpoint. The semantics of marshalling vary according to
                    # the type of endpoint and the content(s) of the inbound message in the supplied exchange.
                    #
                    # For further details, see #ETL::Integration::Engine::Exchange
                    def marshal( exchange )
                        #TODO: REFACTOR -> pull this behaviour up into the superclass, apply template method to marshal (and maybe unmarshal too!?)
                        #                   and finally just throw an exception here.
                        #TODO: consider the impact of the above refactoring suggestion given the existence of such similar code in the Processor class.

                        if exchange.inbound.body.nil?
                            fault_message = Message.new
                            fault_message.set_header(:fault_code, FaultCodes::MissingMessageBody)
                            fault_message.set_header(:fault_description, 'The inbound message of the supplied exchange had no message body (it was nil).')
                            exchange.fault = fault_message
                        else
                            begin
                                _debug("Marshalling data from origin [#{origin(exchange)}] to [#{self.uri}].")
                                file = openio(exchange)
                                file.puts(exchange.inbound.body) unless file.nil?
                            rescue IOError => ex
                                #TODO do something useful here, please!
                                _debug("Unable to marshal to file #{full_path()}: '#{ex.message}'", ex)
                                raise()
                            ensure
                                file.close() unless file.nil?
                            end

                        end
                        return nil
                    end

                    private
                    def resolve_uri( endpoint_uri )
                        unless endpoint_uri.scheme.eql?( 'file' )
                            raise ArgumentError, "the 'endpoint uri' must conform to the FILE scheme", caller
                        end

                        #TODO: reconsider this!?
                        if endpoint_uri.host.nil?
                            @endpoint_uri = endpoint_uri
                        else
                            @endpoint_uri = "#{endpoint_uri.host}:#{endpoint_uri.path}"
                        end
                    end

                    def validate_file_path( endpoint_uri )
                        #puts "trying to validate #{endpoint_uri}"
                        #puts "full path being given as #{full_path()}"
                        unless File.file?(full_path())
                            #TODO: use a hook to deal with this instead
                            _debug("Failed to validate file #{full_path()} against uri #{endpoint_uri}")
                            uriEx = UnresolvableUriException.new( endpoint_uri )
                            raise uriEx, uriEx.message, caller
                        end
                    end

                    def openio(exchange)
                        delimiter = exchange.inbound.headers[:delimiter]
                        return File.open(full_path(), 'a') if delimiter.nil?
                        return FasterCSV.open(full_path(), 'a', {:col_sep => delimiter} )
                    end

                    def build_outbound_exchange(result)
                        #TODO: reuse the superclass method for some of this processing...
                        message = Message.new
                        message.set_header(:uri, @endpoint_uri.dup)
                        #[ :scheme, :path ].each { |property| message.set_header(property, @endpoint_uri.send(property)) }
                        message.set_header(:scheme, @endpoint_uri.scheme)
                        message.set_header(:path, full_path())
                        message.set_header(:basename, File.basename(full_path()))
                        message.set_header(:offset, @last_position)
                        message.body = result
                        exchange = Exchange.new(context)
                        exchange.outbound = message
                        return exchange
                    end

                    #TODO: some unit tests for this please!?

                    def full_path() #:nodoc:
                        unless running_on_windows?
                            host = @endpoint_uri.host || ''
                            unless host.empty?
                                host = File::Separator + host unless host.starts_with?(File::Separator)
                            end
                            path = @endpoint_uri.path
                            path = "#{File::Separator}#{path}" unless path.starts_with?(File::Separator)
                            return host + path
                        end

                        #alt_uri_string = @endpoint_uri.to_s.gsub(/file:\/\//i, 'lfs://')
                        #alt_uri_string = alt_uri_string.gsub(/file:\//i, 'lfs:/') unless alt_uri_string.starts_with?('lfs')
                        #puts "converted alt_uri_string as #{alt_uri_string}"

                        sane_path = @endpoint_uri.path
                        sane_path = sane_path[1..sane_path.size - 1] if sane_path.starts_with?(File::Separator)

                        #alt_uri_string = "lfs:/#{sane_path}"
                        #alternative_notation = URI.parse(alt_uri_string)
                        #return alternative_notation.full_path
                        host = @endpoint_uri.host || ''
                        unless host.empty?
                            host = "#{host}:#{File::Separator}" unless host.ends_with?(":#{File::Separator}")
                        end
                        return "#{host}#{sane_path}"
                    end

                end

            end
        end
    end
end
