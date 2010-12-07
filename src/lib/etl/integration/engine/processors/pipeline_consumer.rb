#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module Processors

                # A processor that delegates to a pipeline and consumer.
                class PipelineConsumer < Processor

                    include Validation
                    
                    attr_reader :uri

                    def initialize(uri, context, consumer, *processors)
                        super()
                        validate_arguments( binding(), :uri, :context, :consumer )
                        @pipeline = Pipeline.new(uri, context, *processors)
                        @consumer = consumer
                        @uri = uri
                    end

                    # Processes the supplied exchange.
                    def do_process(exchange)
                        producer = exchange.create_producer()
                        #TODO: why isn't this unmarshalling!???
                        _info("Forwarding exchange from [#{origin(exchange)}] to pipeline at [#{@pipeline.uri()}] with producer [#{producer.uri()}].")
                        response = @pipeline.execute(producer, @consumer)
                        response.copy_response_to(exchange)
                    end

                end

            end
        end
    end
end
