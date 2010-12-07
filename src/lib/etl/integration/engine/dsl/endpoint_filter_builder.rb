#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module DSL

                # A builder for #EndpointFilter objects...
                class EndpointFilterBuilder < Builder

                    include ExpressionBuilderMixin
                    
                    undef_method :to, :from
                    
                    def accept_visitor(visitor)
                        raise InvalidOperationException, "#{self.class} does not support the visitable interface.", caller()
                    end

                    # Sets the expression used to accept an #Exchange when filtering.
                    # This clause is mutually exclusive with #reject.
                    def accept(expression)
                        unless @expression.nil?
                            raise InvalidOperationException.new(message=
                                    "Unable to set 'accept' as criteria has already been set."), message, caller
                        end
                        validate_arguments(binding(), :expression)
                        assign_expression(expression)
                        return self
                    end

                    # Sets the expression used to reject an #Exchange when filtering.
                    # This clause is mutually exclusive with #accept.
                    def reject(expression)
                        unless @expression.nil?
                            raise InvalidOperationException.new(message=
                                    "Unable to set 'reject' as criteria has already been set."), message, caller
                        end			
                        validate_arguments(binding(), :expression)
                        assign_expression(expression)
                        return self
                    end

                    # Gets the uri for the underlying endpoint.
                    def uri()
                        return @endpoint.uri if @endpoint.respond_to?(:uri)
                        return @endpoint
                    end
                    
                    attr_reader :endpoint
                    
                    def set_endpoint(uri)
                        if uri.kind_of?(Builder)
                            @endpoint = sanitize_builder(consumer)
                        else
                            @endpoint = uri
                        end
                        _debug("Stored consumer #{@endpoint} in builder[#{uri}].")
                        @dependencies.push(uri)
                        return self
                    end
                    
                    def build_product()
                        validate_instance_variables(binding(), :endpoint, :expression)
                        assign_endpoint(@endpoint, "@endpoint", :unmarshal) unless @endpoint.nil?                        
                        return EndpointFilter.new(@endpoint, @expression, context)
                    end

                end
            end
        end
    end
end
