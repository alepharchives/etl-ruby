#!/usr/bin/env ruby
 
require 'rubygems'

module ETL
    module Integration
	module Engine
	    module DSL
		module Lang
		    # A regex pattern matching expression
		    class MatchesExpression < Expression
			def initialize(match_pattern, underlying_expression)
			    validate_arguments(binding())
			    assign_match_pattern(match_pattern)
			    @expression = underlying_expression
			end
			
			# evaluates the supplied exchange using the embedded expression
			# and returns a value indicating whether the response matched the
			# pattern this instance was initialized with.
			def evaluate(exchange)
			    value = @expression.evaluate(exchange)
			    raise_invalid_expression_target(value) unless value.respond_to? :[]
                            _debug("Attemping to match value #{value} against pattern #{@match_pattern}.")
			    return value[@match_pattern]
                        end
			
			private
			def assign_match_pattern(match_pattern)
			    unless match_pattern.kind_of?(Regexp)
				match_pattern = Regexp.compile(match_pattern)
                            end
			    @match_pattern = match_pattern
			rescue RegexpError => ex
			    raise ArgumentError, "Unable to compile regexp match pattern '#{match_pattern}'", caller
                        end
			
			def raise_invalid_expression_target(value)
			    message = "#{self.to_s} cannot evaluate a value of type #{value.class}, " + 
				"as it does not support pattern matching."
			    exception = InvalidExpressionException.create(self, message)
                            _debug(message, exception)
                            raise exception, message, caller()
                        end
		    end
		end
	    end
	end
    end
end
