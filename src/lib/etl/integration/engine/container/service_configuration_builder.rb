#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Container
                # Provides an abstract builder implementation for custom
                # DSL based service builders.
                class ServiceConfigurationBuilder

                    include ETL::Integration::Engine::DSL::ExpressionBuilderMixin
                    include ETL::Integration::Engine::DSL::ProcessorSupportMixin
                    include ETL::Integration::Engine::DSL::BuilderSupportMixin
                    include ETL::Integration::Engine::Container::ServiceExecutionEnvironmentSupport
                    include ETL::Integration::Engine::Container::ServiceExecutionEnvironmentSupport::ModuleDefinitionLoader

                    def initialize
                        @builders = []
                    end

                    # Builds the set of services described by the code in #configure
                    # (an abstract - e.g. undefined - method) and registers them with
                    # the supplied #ExecutionContext.
                    def build(context)
                        #TODO: consider a method object for this...
                        @context = context
                        resolved_expression = self.configure()
                        register_services(context)
                        @context = nil
                        return resolved_expression
                    end

                    protected

                    attr_reader :context

                    # Configures the builders which will be used to define services
                    # on an #ExecutionContext at runtime.
                    def configure()
                        raise NotImplementedException, "Subclasses need to implement 'configure' for themselves.", caller()
                    end

                    # A hook so that evaluated code can contain 'include'
                    # statements without falling over...
                    def include(const_name)
                        self.class.send(:include, const_name)
                    end

                    private

                    # builds up the internal service definitions and adds them to
                    # the supplied context.
                    def register_services(context)
                        visitor = ServiceBuilderVisitor.new(context)
                        @builders.each do |builder|
                            builder.accept_visitor(visitor) unless context.registered?(builder.uri)
                        end
                    end

                end
            end
        end
    end
end
