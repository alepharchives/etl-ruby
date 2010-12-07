#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module DSL
                # A builder class used internally by the DSL to generate
                # domain objects fulfilling the contract(s) specified in
                # (dsl) code by an application.
                class Builder

                    mixin Validation
                    #mixin BuilderSupportMixin

                    attr_reader :producer, :consumer

                    # Gets or sets the uri for the current instance.
                    attr_accessor :uri

                    initialize_with :context, :attr_reader => true, :validate => true do
                        @dependencies = []
                        unless self.respond_to?(:build_product)
                            raise RuntimeError, "Subclass does not implement 'build_product()' method.", caller()
                        end
                    end

                    # Sets the producer for the endpoint (or pipeline).
                    # The producer can be a string, URI instance or an object that
                    # implements the 'unmarshaling' part of the #Endpoint interface.
                    def from(producer)
                        if producer.kind_of?(Builder)
                            @producer = sanitize_builder(producer)
                        else
                            @producer = producer
                        end
                        _debug("Stored producer #{@producer} in builder[#{ (uri.nil?) ? 'uri unknown' : uri }].")
                        @dependencies.push( producer )
                        return self
                    end

                    # Sets the consumer for the pipeline.
                    # consumer can be a string, URI instance or an object that
                    # implements the 'marshaling' part of the #Endpoint interface.
                    def to(consumer)
                        if consumer.kind_of?(Builder)
                            @consumer = sanitize_builder(consumer)
                        else
                            @consumer = consumer
                        end
                        _debug("Stored consumer #{@consumer} in builder[#{ (uri.nil?) ? 'uri unknown' : uri }].")
                        @dependencies.push( consumer )
                        return self
                    end

                    # Accepts the supplied visitor, implementing the 'Visitable' part
                    # of a stereotypical visitor pattern implementation.
                    #
                    # This implementation uses the acyclic-visitor variation on the pattern,
                    # which is especially useful given Ruby's duck typing (polymorphic dispatch
                    # doesn't work the same way as it would in a language using manifest typeing).
                    def accept_visitor(visitor)
                        visit_method_name = "visit#{basename(self.class.name.to_s.gsub(/::/, '/'))}".to_sym
                        visitor.send(visit_method_name, self) if visitor.respond_to?(visit_method_name)
                    end

                    # Returns the product for the current builder.
                    def product()
                        assign_endpoint(@producer, "@producer", :unmarshal) unless @producer.nil?
                        #TODO: why the heck was this checking for unmarshal!?
                        assign_endpoint(@consumer, "@consumer", :marshal) unless @consumer.nil?
                        return build_product()
                    end

                    def depends_on
                        @dependencies
                    end

                    protected

                    def sanitize_builder(builder)
                        visitor = ServiceBuilderVisitor.new(context())
                        builder.accept_visitor(visitor)
                        return builder.uri
                    end

                    # Assigns the supplied endpoint (or uri) to the given fieldname, asserting the
                    # underlying endpoint/service object's compliance with the supplied interface_specification.
                    def assign_endpoint(endpoint, fieldname, interface_specification)
                        instance_variable_set(fieldname, sanitize_endpoint(endpoint, interface_specification))
                    end

                    # Sanitizes the supplied endpoint against the given interface specification.
                    def sanitize_endpoint(endpoint, interface_specification)
                        if endpoint.kind_of? String
                            return sanitize_endpoint(@context.lookup_uri(endpoint), interface_specification)
                        end
                        unless endpoint.respond_to? interface_specification
                            endpoint = @context.lookup_uri("#{endpoint.uri()}?api=#{interface_specification}")
                        end
                        endpoint
                    end

                    def assign_expression(expression)
                        message = "The supplied expression must respond to 'evaluate'"
                        raise InvalidExpressionException.create(expression, message) unless expression.respond_to? :evaluate
                        instance_variable_set("@expression", expression)
                    end

                end
            end
        end
    end
end
