#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module DSL
                module Lang
                    # Defines an expression that can evaluate an #Exchange
                    # to return a value (the actual outcome of evaluation is
                    # implementation specific).
                    class Expression

                        include Validation
                        include ETL::Integration::Engine::RuntimeSupportMixin

                        class << self
                            # Creates 'binary operator' methods based on the supplied array of names.
                            # Each symbol is used to define an instance method, which takes an expression as its
                            # input argument and returns a #BinaryExpression combining the 'self' instance, the
                            # input expression (as an rvalue) and the operator itself (as the message to dispatch).
                            #
                            # See the #BinaryExpression class for more details on binary expression evaluation.
                            def binary_operator( *operator_names )
                                _debug("Setting binary operations for #{operator_names.inspect}.")
                                operator_names.each do |operator_symbol|
                                    define_method(operator_symbol) do |otherExpression|
                                        return BinaryExpression.new(self, otherExpression, operator_symbol)
                                    end
                                end
                            end

                            # Creates a conversion method for each of the supplied 'expressions'.
                            # The conversion method will return an instance of the class defined by combining the
                            # expression name (e.g. 'equals') and the Expression constant (i.e. EqualsExpression)
                            # and calling the constructor with the supplied arguments. The 'self' reference to the calling
                            # instance is always passed as the final argument to <code>clazz.new</code>
                            def conversion_to( *expressions )
                                _debug("Setting conversion methods for #{expressions.inspect}.")
                                expressions.each do |expr|
                                    clazz = eval("#{expr.to_s.capitalize}Expression")
                                    unless clazz.kind_of?(Class)
                                        raise InvalidExpressionException.create(expr, msg="#{expr} is not an expression!"), msg, caller
                                    end
                                    define_method(expr) do |*args|
                                        clazz.send(:new, *(args + [self]))
                                    end
                                end
                            end
                        end

                        # initializes an instance of the #Expression class.
                        # uses #evaluator to define the #evaluate method if supplied.
                        def initialize(&evaluator)
                            @evaluator = evaluator unless evaluator.nil?
                        end

                        # Evaluates the supplied exchange, possibly returning a value.
                        # Subclasses need to override this method, unless an evaluator
                        # block has been supplied during initialization, in which case
                        # evaluation is delegated to the block.
                        def evaluate(exchange)
                            return method_missing(:evaluate, exchange) unless @evaluator
                            response = @evaluator.call(exchange)
                            _debug("Evaluating exchange against proc [#{@evaluator}] and responding with [#{response}].")
                            return response
                        end

                        # Creates a new sub-expression, which forwards the supplied method_name
                        # and arguments (if present) to the result of #evaluate and returns it
                        # it its raw (data) form.
                        def send_method(method_name, *args)
                            me = self
                            return Expression.new do |exchange|
                                me.evaluate(exchange).send(method_name, *args)
                            end
                        end

                    end
                end
            end
        end
    end
end
