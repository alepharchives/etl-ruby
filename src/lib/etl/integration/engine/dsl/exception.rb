#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
	module Engine
	    module DSL
		
		# I am raised when an expression is used in a invalid context,
		# or does not respond to the 'evaluate(exchange)' message
		class InvalidExpressionException < ExecutionException
		    
		    initialize_with :expression, :attr_reader => true, :validate => true
		    
		    attr_accessor :message
		    
		    def message
			return @message ||= "The supplied expression must respond to 'evaluate'"
                    end
		    
		    def InvalidExpressionException.create(expression, message)
			instance = InvalidExpressionException.new(expression)
			instance.message = message
			return instance
		    end
		end
	    end
	end
    end
end
