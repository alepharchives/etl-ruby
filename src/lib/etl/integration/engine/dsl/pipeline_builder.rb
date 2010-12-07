#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module DSL
                # A builder implementation for #Pipeline creation.
                class PipelineBuilder < Builder

                    def initialize(context)
                        super(context)
                        @steps = []
                    end
                    
                    mixin ProcessorSupportMixin

                    def via(*processors)
                        raise ArgumentError, "a 'processor' cannot be nil", caller if processors.include? nil
                        processors.each { |processor| assign_processor(processor) }
                        return self
                    end

                    protected

                    def build_product()
                        validate_instance_variables(binding(), :producer, :consumer, :uri)
                        if steps.empty?
                            return PipelineProcessor.new(Pipeline.new(uri, context), @producer, @consumer)
                        else
                            return PipelineProcessor.new(Pipeline.new(uri, context, *@steps), @producer, @consumer)
                        end
                    end

                    def assign_processor(processor)
                        unless processor.respond_to? :process
                            raise ArgumentError, "Processors must respond to a 'process' message.", caller
                        end
                        steps.push(processor)
                    end

                    def steps
                        @steps
                    end

                end
            end
        end
    end
end
