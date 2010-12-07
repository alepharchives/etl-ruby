#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Container
                # Provides a <code>Visitor</code> interface for #Builder instances
                # and implements the <i>Acyclic Visitor Pattern</i>.
                class ServiceBuilderVisitor

                    immutable_attr_reader :visited

                    initialize_with :context, :validate => true do
                        @visited = []
                    end

                    def visitPipelineBuilder(pipeline_builder)
                        @context.register_pipeline(pipeline_builder.product()) unless @context.registered?(pipeline_builder.uri)
                        @visited.push(pipeline_builder)
                    end

                    def visitEndpointFilterBuilder(endpoint_builder)
                        #TODO: reconsider what this really should do....
                        @context.register_endpoint(endpoint_builder.producer()) unless @context.registered?(endpoint_builder.producer())
                        filtered_endpoint = endpoint_builder.product()
                        @context.register_endpoint(filtered_endpoint) unless @context.registered?(
                            (filtered_endpoint.respond_to?(:uri)) ? filtered_endpoint.uri : filtered_endpoint
                        )
                        @visited.push(endpoint_builder)
                    end

                    def visitPipelineConsumerBuilder(consumer_builder)
                        @context.register_consumer(consumer_builder.product()) unless @context.registered?(consumer_builder.uri)
                        @visited.push(consumer_builder)
                    end

                    def visitServiceBuilder(service_builder)
                        @context.register_service(service_builder.product()) unless @context.registered?(service_builder.uri)
                        @visited.push(service_builder)
                    end

                end
            end
        end
    end
end
