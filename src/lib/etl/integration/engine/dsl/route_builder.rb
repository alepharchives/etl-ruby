#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module DSL
                # A builder implementation for routing (e.g. redirects).
                class RouteBuilder < PipelineBuilder
                    
                    include ExpressionBuilderMixin
                    
                    undef_method :from

                    # Gets the router type associated with the current instance (Router or MulticastRouter)
                    attr_reader :router_type

                    # Sets the expression which is used by the current route 
                    # specification to evaluate in inbound message exchange.
                    def where(expression)
                        unless __current_specification.expression.nil?
                            raise InvalidOperationException.new(message=
                                    "Unable to set 'accept' as criteria has already been set."), message, caller
                        end
                        validate_arguments(binding(), :expression)
                        assign_expression(expression)
                        __current_specification.expression = @expression
                        return self
                    end
                    
                    # Synonym for #where
                    alias whenever where
                    
                    # Sets a default 'otherwise' clause which always evaluates
                    # to <code>true</code> and sets the #where clause for the current route specification.
                    def otherwise()
                        raise InvalidOperationException, "Cannot set 'otherwise' clause before setting a router type (e.g. and/or).", caller if router_type.nil?
                        prepare_next_route()
                        where(Expression.new { true })
                        @otherwise = true
                        return self
                    end
                    
                    # Sets a #DeadLetterChannel and <b>does not</b> reset the next route.
                    def ignore()
                        raise InvalidOperationException, "Cannot set 'ignore' clause before setting 'otherwise'.", caller() unless @otherwise
                        to(DeadLetterChannel.new())
                        return self
                    end

                    # Sets the steps used to process the current route (making it a sub-pipeline).
                    def via(*processors)
                        super
                        __current_specification.steps = @steps.dup
                        return self
                    end

                    # Sets the destination uri (or #Endpoint) for the current route.
                    def to(destination)
                        #TODO: explode if it's already set!
                        @dependencies.push( destination )
                        __current_specification.destination = destination
                        return self
                    end

                    # Defines the #router_type for this builder as a #MulticastRouter.
                    def and()
                        verify_router_type(MulticastRouter)
                        prepare_next_route()
                        return self
                    end

                    # Defines the #router_type for this builder as a #Router (unicast).
                    def or()
                        verify_router_type(Router)
                        prepare_next_route()
                        return self
                    end

                    # Gets the current route specification.
                    def current_specification
                        __current_specification.dup
                    end

                    protected
                    
                    # Gets the product back from this buidler.
                    def build_product()
                        #validate_instance_variables(binding(), :foo)
                        router = (router_type || Router).new
                        prepare_next_route()
                        @routes.each do |route_specification|
                            endpoint = sanitize_endpoint(route_specification.destination, :marshal)
                            if route_specification.steps.nil? || route_specification.steps.empty?
                                router.add_route(route_specification.expression, endpoint)
                            else
                                processor = PipelineConsumer.new(endpoint, *route_specification.steps)
                                adapter = ProcessorEndpoint.new(endpoint.uri, context(), processor)
                                router.add_route(route_specification.expression, adapter)
                            end
                        end
                        return router
                    end
                    
                    # Sanitizes the supplied endpoint against the given interface specification. 
                    def sanitize_endpoint(endpoint, interface_specification)
                        original_endpoint = endpoint.dup
                        endpoint = super(endpoint, interface_specification)
                        raise ex=UnresolvableUriException.new(original_endpoint), ex.message, caller() unless endpoint.respond_to?(interface_specification)
                        return endpoint
                    end                    

                    private

                    def __current_specification
                        @current_specification ||= RouteSpecification.new
                    end

                    #RouteSpecification = Struct.new(:expression, :destination, :steps)

                    class RouteSpecification
                        attr_accessor :expression, :destination, :steps
                        
                        # Asserts that this route specification meets the minimum requirement (has an expression and a destination set)
                        def validate()
                            if self.expression.nil?
                                raise InvalidOperationException, "The current route specification has no condition set.", caller
                            end
                            if self.destination.nil?
                                raise InvalidOperationException, "The current route specification has no destination set.", caller
                            end
                        end
                    end
                    
                    def routes()
                        @routes ||= []
                    end

                    def prepare_next_route()
                        __current_specification.validate
                        routes.push(__current_specification)
                        steps.clear()
                        @current_specification = RouteSpecification.new
                    end

                    def verify_router_type(clazz)
                        if @router_type.nil?
                            @router_type = clazz
                        else
                            if @router_type.eql?(Router)
                                on_router_type_already_set('or')
                            elsif @router_type.eql?(MulticastRouter)
                                on_router_type_already_set('and')
                            end
                        end
                    end

                    def on_router_type_already_set(type_desriptor)
                        raise InvalidOperationException,
                            "The router type has already been set to '#{type_desriptor}' and cannot be changed!", caller
                    end

                end
            end
        end
    end
end
