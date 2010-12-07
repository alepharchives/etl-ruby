#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
	module Engine
	    module DSL
		module Lang
		    # A conditional expression that resolves true or false 
		    # based on the inverse of the underlying expression (uses delegation).
		    class UnlessExpression < Expression

			# a binary 'and' operation, to support expression chaining.
			binary_operator :&
			# a binary 'or' operation, to support expression chaining.
			binary_operator :|			
			# synonym for #&
			alias_method :and, :&
			# synonym for #| 
			alias_method :or, :|
			
			def initialize(underlying_expression)
			    validate_arguments(binding())
			    @underlying_expression = underlying_expression
                        end
			
			# Evaluates the supplied exchange, returning a true/false value
                        # which is the inverse of the delegated evaluation..			
			def evaluate(exchange)
			    return false if @underlying_expression.evaluate(exchange)
			    return true
                        end
		    end
		end
	    end
	end
    end
end
