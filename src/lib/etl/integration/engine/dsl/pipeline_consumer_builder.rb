#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module DSL
                # A builder implementation for pipeline consumers (AKA the #PipelineConsumer)
                class PipelineConsumerBuilder < PipelineBuilder

                    undef_method :from

                    def build_product()
                        validate_instance_variables(binding(), :consumer, :uri)
                        if @steps.nil?
                            return PipelineConsumer.new(uri, context, @consumer)
                        else
                            return PipelineConsumer.new(uri, context, @consumer, *@steps)
                        end
                    end

                end
            end
        end
    end
end
