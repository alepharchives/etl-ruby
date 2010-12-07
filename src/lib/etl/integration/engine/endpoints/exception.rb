#!/usr/bin/env ruby
 
require 'rubygems'

module ETL
    module Integration
        module Engine
            module Endpoints
                
                # I am raised whenever an unresolvable uri is encountered.
                class UnresolvableUriException < ExecutionException
                    initialize_with :uri, :attr_reader => true, :validate => true
                    def message
                        "Unable to resolve uri #{self.uri}."
                    end
                end
                
#		# I am raised whenever an invalid endpoint pops it's head up!
#		class InvalidEndpointException < ExecutionException
#		    initialize_with :endpoint, :attr_reader => true
#		    def message
#			"#{self.endpoint.inspect} is not a valid endpoint."
#                    end
#                end
		
            end
        end
    end
end
