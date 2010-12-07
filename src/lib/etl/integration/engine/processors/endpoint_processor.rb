#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Processors
                # A processor which delegates directly to an #Endpoint
                class EndpointProcessor < Processor
                    
                    include Validation
                    
                    def initialize(endpoint)
                        super()
                        validate_arguments(binding())
                        @endpoint = endpoint
                    end
                    
                    protected
                    
                    def do_process(exchange)
                        _info("Forwarding exchange from [#{origin(exchange)}] to endpoint at [#{@endpoint.uri()}].")
                        @endpoint.marshal(exchange)
                    end
                    
                end
            end
        end
    end
end
