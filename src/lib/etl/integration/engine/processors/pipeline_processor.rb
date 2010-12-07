#!/usr/bin/env ruby

require "rubygems"
 

module ETL
    module Integration
        module Engine
            module Processors
                # A processor that kicks off a #Pipeline#execute call and puts
                # the response into the supplied #Exchange.
                class PipelineProcessor < Processor
                    
                    include Validation
                    
                    attr_reader :pipeline, :producer, :consumer             
                    
                    def initialize(pipeline, producer, consumer)
                        super()
                        validate_arguments(binding())
                        @pipeline, @producer, @consumer = pipeline, producer, consumer
                    end
                    
                    def uri
                        return "#{@pipeline.uri}/processor"
                    end                    
                    
                    protected
                    
                    def do_process(exchange)
                        @pipeline.execute(@producer, @consumer).copy_response_to(exchange)
                        set_outbound_header(exchange, :producer, @producer)
                        set_outbound_header(exchange, :consumer, @consumer)                        
                    end
                    
                end
            end
        end
    end
end
