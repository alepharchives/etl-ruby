#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Endpoints

                # An endpoint which reponds to marshalled exchanges by
                # forwarding them to a given #Processor. This endpoint does 
                # not support consumers (e.g. doesn't implement an #unmarshal method)
                # and takes its uri from its parent.
                class ProcessorEndpoint < Endpoint

                    def initialize(endpoint_uri, execution_context, processor)
                        super(endpoint_uri, execution_context)
                        validate_arguments(binding, :processor)
                        @processor = processor
                    end

                    # *Not implemented*
                    def unmarshal()
                        ex = NotImplementedException.new()
                        message = "#{self.class} at [#{self.uri()}] cannot unmarshal exchanges."
                        _info(message, ex, self)
                        raise ex, message, caller()
                    end

                    # Marshalls the supplied exchange to the underlying processor.
                    def marshal(exchange)
                        super(exchange)
                        @processor.process(exchange)
                    end

                    private
                    def resolve_uri(uri)
                        return true
                    end
                end
            end
        end
    end
end
