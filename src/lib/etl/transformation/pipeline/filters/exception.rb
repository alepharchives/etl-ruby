#!/usr/bin/env ruby

require 'rubygems'

#TODO: this file should be named exception.rb!!!

module ETL
    module Transformation
        module Pipeline
            module Filters

                # I represent an API violation that occurs whenever a filter
                # fails to perform it's given operation(s).
                #
                class FilterException < StandardError
		    attr_reader :message, :filter, :input_data, :cause
                    def initialize(message=nil, filter=nil, input_data=nil, cause=nil)
			@message, @filter, @input_data, @cause = 
			    message, filter, input_data, cause
                    end
                end

                class MissingFilterException < StandardError
                    attr_reader :cause
                    def initialize( message=$!, cause=$ERROR_INFO )
                        super( message )
                        #local_variables.each { |var| instance_variable_set( "@#{var}", eval( var ) ) }
                        @cause = cause
                    end
                end

            end
        end
    end
end
