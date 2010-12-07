#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module DSL
                module Lang
                    # A binary expression, taking two operands (lvalue and rvalue) and an operator.
                    # The operator must correlate directly to a message supported on the result of 
                    # evaluting the lvalue and taking one input argument (which, at runtime, will be
                    # the result of evaluating the rvalue if [it] responds to :evaluate, otherwise the
                    # rvalue will be passed verbatim).
                    class BinaryExpression < Expression
                        def initialize( lvalue, rvalue, operator )
                            _debug("Creating binary expression based on lvalue(#{lvalue}) and rvalue(#{rvalue}).")
                            validate_arguments(binding(), :lvalue, :rvalue, :operator)
                            @lvalue, @rvalue, @operator = lvalue, rvalue, operator
                        end

                        # Evaluates the supplied exchange, possibly returning a value;
                        # evaluation occurs on the left operand first, passing the operator to
                        # the result along with the evaluated response of the right operand (or
                        # the right operand itself, if it is not 'evaluat-able').
                        def evaluate(exchange)
                            _debug("Binary evaluating exchange from [#{origin(exchange)}].")
                            @lvalue.evaluate(exchange).send(@operator, resolved_rvalue(exchange))
                        end

                        private
                        def resolved_rvalue(exchange)
                            return @rvalue unless @rvalue.respond_to?(:evaluate)
                            return @rvalue.evaluate(exchange)
                        end
                    end		    
                end
            end
        end
    end
end
