#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module DSL
                # Provides DSL methods for top level workflow declaration(s).
                module BuilderSupportMixin

                    # Sets the default fault channel for the current context.
                    def default_fault_channel(fault_channel)
                        context().default_fault_channel = fault_channel
                    end

                    # Creates a #ServiceBuilder and returns it.
                    #
                    # A service encapsulates a set of processing steps and
                    # looks (externally) like an endpoint (e.g. you can 'marshal'
                    # data into it).
                    def service(uri, &block)
                        service = ServiceBuilder.new(context())
                        service.uri = uri
                        __builders.push(service)
                        service.instance_eval(&block) if block_given?
                        return service
                    end

                    # Creates a #PipelineBuilder and returns it.
                    #
                    # Pipelines encapsulate the functionality to unmarshal data from a producer
                    # via zero or more processing steps and marshals it into a consumer.
                    def pipeline(uri)
                        builder = PipelineBuilder.new(context())
                        builder.uri = uri
                        __builders.push(builder)
                        return builder
                    end

                    # Creates a #PipelineConsumerBuilder instance and returns it.
                    # Consumers are designed in the same way as pipelines, except
                    # they do not have explicit producers (i.e. the 'from' directive).
                    def consumer(uri)
                        builder = PipelineConsumerBuilder.new(context())
                        builder.uri = uri
                        __builders.push(builder)
                        return builder
                    end

                    # Takes a uri and returns an #EndpointFilterBuilder.
                    #
                    # TODO: documentation... :P
                    #
                    def filter(uri_or_ref, &block)
                        uri = uri_or_ref
                        if uri.kind_of?(Builder)
                            visitor = ServiceBuilderVisitor.new(context())
                            uri_or_ref.accept_visitor(visitor)
                            uri = uri_or_ref.uri
                        end
                        raise ExecutionException, "no block given!", caller() unless block_given?

                        builder = EndpointFilterBuilder.new(context())
                        builder.set_endpoint(uri)
                        builder.instance_eval(&block)

                        context().lookup_uri(builder.uri())
                        filtered_endpoint = builder.product()
                        context().register_endpoint(filtered_endpoint)
                        return filtered_endpoint
                    end
                    
                    def builders
                        return __builders.dup.freeze
                    end

                    private

                    #TODO: not sure if this is safe!???
                    def __builders
                        @builders ||= []
                    end

                end
            end
        end
    end
end
