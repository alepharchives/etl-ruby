#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module Endpoints

                # An endpoint that acts as a proxy/gateway around another endpoint
                # and applies filtering to each interaction with its delegate.
                class EndpointFilter < Endpoint

                    def initialize(endpoint, filter, execution_context)
                        temp_cache_endpoint_for_initializer_validation(endpoint)
                        validate_arguments(binding, :endpoint, :filter)
                        super(endpoint.uri, execution_context)
                        @endpoint, @filter = endpoint, filter
                    end

                    def uri()
                        uri = @endpoint.uri.to_s
                        return "#{uri}#{'/' unless uri.ends_with?('/')}filtered"
                    end

                    # Unmarshals the next message exchange from this endpoint.
                    # Clients can repeatedly call this method to consume
                    # multiple exchanges until it returns 'nil', which indicates
                    # that the endpoint has finished producing.
                    def unmarshal()
                        #TODO: this doesn't look right. How can the filter evaluate 'nil' correctly?
                        #NB: I changed this to unmarshal initially before continuing, but I'm not sure if that's correct either!?
                        _info("#{self.class} at [#{self.uri()}] applying filters.")
                        exchange = @endpoint.unmarshal()
                        return nil if exchange.nil?
                        until @filter.evaluate( exchange )
                            exchange = @endpoint.unmarshal()
                            return nil if exchange.nil?
                        end
                        super()
                        return exchange
                    end

                    # Marshalls the supplied exchange to this endpoint.
                    # The semantics of marshalling vary according to the type of endpoint
                    # and the content(s) of the inbound message in the supplied exchange.
                    #
                    # For further details, see #ETL::Integration::Engine::Exchange
                    def marshal( exchange )
                        _info("#{self.class} at [#{self.uri()}] filtering exchange from [#{origin(exchange)}].")
                        if @filter.evaluate( exchange )
                            super(exchange)
                            @endpoint.marshal( exchange )
                        end
                    end

                    private
                    def resolve_uri(uri)
                        return @endpoint.uri.eql?(uri)
                    end

                    def temp_cache_endpoint_for_initializer_validation(endpoint)
                        @endpoint = endpoint
                    end

                end

            end
        end
    end
end
