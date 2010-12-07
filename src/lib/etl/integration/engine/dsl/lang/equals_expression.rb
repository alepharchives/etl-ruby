#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module DSL
                module Lang
                    # An equality test expression
                    class EqualsExpression < Expression

                        attr_reader :expected_value

                        # a binary 'and' operation, to support expression chaining.
                        binary_operator :&
                        # a binary 'or' operation, to support expression chaining.
                        binary_operator :|			
                        # synonym for #&
                        alias_method :and, :&
                        # synonym for #| 
                        alias_method :or, :|

                        initialize_with :expected_value, :underlying_expression

                        # Evaluates the supplied exchange, returning a (true|false) value that indicates
                        # whether or not the underlying expression matched the expected value.
                        def evaluate(exchange)
                            return @underlying_expression.evaluate(exchange).eql?(@expected_value)
                        end
                    end
                end
            end
        end
    end
end
