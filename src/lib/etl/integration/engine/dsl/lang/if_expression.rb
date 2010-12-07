#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
	module Engine
	    module DSL
		module Lang
		    # A conditional expression that resolves true or false 
		    # based on the underlying expression (uses delegation).
		    class IfExpression < Expression
			def initialize(underlying_expression)
			    validate_arguments(binding())
			    @expression = underlying_expression
			end
			
			# Evaluates the supplied exchange, returning true or false.
			def evaluate(exchange)
			    return ( @expression.evaluate(exchange) ) ? true : false
                        end
		    end
		end
	    end
	end
    end
end
