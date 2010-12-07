#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module DSL
                # A builder implementation for #Service objects
                class ServiceBuilder < PipelineBuilder

                    def initialize(context)
                        super(context)
                    end
                    
                    undef_method :to, :from

                    alias sequence via

                    def product()
                        raise InvalidOperationException.new(message="'steps' not set"), message, caller() if @steps.empty?
                        validate_instance_variables binding(), :uri
                        #TODO: steps!
                        if steps.empty?
                            return Service.new(uri, context)
                        else
                            return Service.new(uri, context, *steps)
                        end
                    end
                end
            end
        end
    end
end
