#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Endpoints

                # An endpoint that acts as a granularity conversion over another endpoint.
                class Splitter < Endpoint

                    def initialize(endpoint, context)
                        validate_arguments(binding(), :endpoint, :context)
                        super(endpoint.uri, context)
                        @endpoint = endpoint
                        puts endpoint.inspect
                        @uri = "#{@endpoint.uri()}/splitter"
                    end

                    # Unmarshals data/exchanges from the underlying endpoint, 
                    # creating a producer for each and extracting it's outputs
                    # one by one before moving onto the next exchange.
                    def unmarshal()
                        unless @producer.nil?
                            exchange = @producer.unmarshal()
                            return exchange unless exchange.nil?
                        end
                        exchange = @endpoint.unmarshal()
                        return nil if exchange.nil?
                        @producer = exchange.create_producer()
                        return unmarshal() unless @producer.nil?
                        return nil
                    end

                    # Creates a producer for the incoming exchange and marshals
                    # a complete data set (i.e. all the exchanges it will produce)
                    # to the underlying endpoint.
                    def marshal(exchange)
                        #puts "hmn..."
                        producer = exchange.create_producer()
                        #puts "got producer #{producer.inspect}"
                        until (last_exchange = producer.unmarshal()).nil?
                            #puts "marshalling #{last_exchange.outbound.inspect} to #{@endpoint.inspect}..."
                            @endpoint.marshal(last_exchange.flip())
                            #puts "marshalled..."
                            final_exchange = last_exchange
                        end
                        #puts "copying response..."
                        final_exchange.copy_response_to(exchange)
                    end

                    protected

                    def resolve_uri(uri)
                        return true
                    end

                end
            end
        end
    end
end
