# #!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module Endpoints

                # An #Endpoint for a local file system directory.
                class DirectoryEndpoint < Endpoint

                    # Unmarshals the next message exchange from this endpoint. Clients can repeatedly call this method
                    # to consume multiple exchanges until it returns 'nil', which indicates that the endpoint has
                    # finished producing.
                    def unmarshal
                        super()
                        if @unmarshaller.nil?
                            directory_entries = get_directory_entries
                            @unmarshaller = lambda {
                                return nil if directory_entries.empty?
                                exchange = build_outbound_exchange( directory_entries.shift() )
                                _info("Built outbound exchange [#{origin(exchange)}].", nil, self)
                                return exchange
                            }
                        end
                        return @unmarshaller.call()
                    end
                    
                    def marshal(exchange)
                        ex = NotImplementedException.new
                        message = "Directory endpoints do not support marshalling."
                        _info(message, ex, self)
                        raise ex, message, caller()
                    end

                    def reset()
                        _info("Resetting #{self.class} at [#{self.uri()}].")
                        @unmarshaller = nil
                    end

                    private

                    def get_directory_entries
                        Dir.entries( @endpoint_uri.full_path ).delete_if { |item| [ '.', '..', '-' ].include?( item ) }
                    end

                    def resolve_uri( endpoint_uri )
                        unless endpoint_uri.scheme.eql?( 'lfs' )
                            raise ArgumentError, "the 'endpoint uri' must conform to the LFS scheme", caller
                        end
                        unless File.directory? endpoint_uri.full_path
                            uriEx = UnresolvableUriException.new( endpoint_uri )
                            #TODO: a cleaner approach perhaps!?
                            begin
                                raise uriEx, uriEx.message, caller
                            rescue UnresolvableUriException => ex
                                _debug("Unable to resolve directory uri '#{endpoint_uri.full_path}'.", ex)
                                raise()
                            end
                        end
                    end

                    def build_outbound_exchange( entry )
                        #TODO: URGENT - fix me...
                        full_path = File.join(@endpoint_uri.full_path, entry)
                        scheme = ( File.file?( full_path ) ) ? 'file' : 'lfs'
                        suffix = full_path.ends_with?(File::Separator) ? '' : File::Separator
                        case scheme
                        when 'lfs'
                            if running_on_windows?
                                full_path = "#{full_path}#{suffix}"
                            else
                                prefix = full_path.starts_with?(File::Separator) ? '' : File::Separator 
                                full_path = "#{prefix}#{full_path}#{suffix}"
                            end
                        when 'file'
                            #TODO: anything?
                        end
                        exchange = super( scheme, entry )
                        #overwriting the :uri header is certainly a hack; how to improve on this...
                        #TODO: platform specific conversion!?
                        uri = URI.parse("#{scheme}:/#{full_path}")
                        exchange.outbound.set_header(:uri, uri)
                        exchange.outbound.set_header(:path, full_path)
                        return exchange
                    end

                end

            end
        end
    end
end
