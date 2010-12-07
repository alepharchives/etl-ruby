#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine

            #
            # An #Exchange is used to marshal and unmarshal data and/or
            # messages to and from an #Endpoint. A #Message can be used to pass on
            # commands, events, or just used as a Data Transfer Object to shuffle data
            # (and context) around the system.
            #
            class Exchange

                include Validation

                # Gets or sets the inbound message or channel.
                attr_accessor :inbound

                # Gets or sets the outbound message or channel.
                attr_accessor :outbound

                # Gets or sets a fault message (or channel), indicating some
                # kind of processing error.
                attr_accessor :fault

                # Gets the execution context for the current instance
                attr_reader :context

                # Has the initializing action failed (e.g. is there a fault or exception object)?
                def has_fault?
                    @fault
                end

                def initialize( execution_context )
                    validate_arguments(binding())
                    @context = execution_context
                end
                
                # Makes a copy of this exchange...
                def copy()
                    acopy = Exchange.new(@context)
                    acopy.inbound = self.inbound
                    acopy.fault = self.fault
                    return acopy
                end

                # Flips the current exchange, creating a new copy whose #inbound
                # property is initialized with the current outbound channel.
                # Any #fault set on the current exchange is copied to the :fault header of
                # the #inbound channel on the new exchange.
                def flip()
                    acopy = perform_copy_operation(:outbound => :inbound)
                    acopy.inbound.set_header(:fault, self.fault) if self.has_fault?
                    return acopy
                end

                # Reverses the current exchange, creating a new copy whose #inbound
                # is set to the #outbound channel of this exchange and whose #outbound
                # is set to the #inbound channel of this exchange.
                def reverse()
                    return perform_copy_operation(
                        :inbound => :outbound,
                        :outbound => :inbound,
                        :fault => :fault
                    )
                end

                # Copies the response (outbound and fault) from the current instance
                # into a new exchange which is then returned.
                def copy_response_to( exchange )
                    return perform_copy_operation(
                        :outbound => :outbound,
                        :fault => :fault
                    ) { exchange }
                end

                def eql?( other )
                    [ :inbound, :outbound, :fault ].each do |property|
                        return false unless other.send(property).eql?( self.send(property) )
                    end
                    return true
                end

                # Creates an #Endpoint based on the uri-scheme of the #inbound message channel
                # Raises #UnresolvableUriException if the inbound uri cannot be resolved to an
                # appropriate producer type.
                def create_producer()
                    #TODO: consider a subclass to do this perhaps!?
                    hash = inbound.headers
                    uri = hash.fetch(:safe_path, nil) || hash[:uri]
                    endpoint = context.lookup_uri(uri)
                    raise ex=UnresolvableUriException.new(uri), ex.message, caller unless endpoint.respond_to? :unmarshal
                    
                    return EndpointProxy.new(endpoint, hash)
                end
                
                private
                
                class EndpointProxy
                    def initialize(delegate, headers)
                        @delegate = delegate
                        @headers = headers
                    end
                    
                    def method_missing(sym, *args)
                        response = @delegate.send(sym, *args)
                        if sym.eql?(:unmarshal)
                            @headers.each do |key, value|
                                unless response.outbound.headers.has_key?(key)
                                    response.outbound.set_header(key, value) 
                                end
                            end
                        end
                        return response
                    end
                end

                def perform_copy_operation(mappings)
                    acopy = ( block_given? ) ? yield : Exchange.new(@context)
                    mappings.each do |myproperty, itsproperty|
                        acopy.send("#{itsproperty}=".to_sym, self.send(myproperty))
                    end
                    return acopy
                end

            end

        end
    end
end
