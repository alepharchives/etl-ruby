#!/usr/bin/env ruby

require "rubygems"

module ETL
    # The base exception class for all our custom exceptions
    class BaseException < StandardError
        
        attr_reader :message, :cause, :output
        
        alias inner_exception cause
        
        def initialize(message=$!, cause=$ERROR_INFO)
            @message, @cause = message, cause
        end
        
        # Gets the body of this exception. 
        #
        # What this actually means is implementation specific.
        # The exception's body is used to construct detailed 
        # debugging and fault logging information throughout the
        # system. 
        # 
        # By default, this message will construct a detailed stack
        # trace and audit history, returning it as a string.
        #
        def process_body()
            format_exception(self, build_error_message())
        end
        
        def build_error_message
            @output = []
            @output.push [
                "START-ERROR-INFO: ",
                "[timestamp: #{Time.now}]"].join('')
            
            iterate_cause_hierarchy(self)
            
            @output.push [
                "END-ERROR-INFO"
            ].join( '' )
        end
        
        def iterate_cause_hierarchy(cause)            
            process_cause(cause)
            
            if cause.respond_to?(:inner_exception) 
                iterate_cause_hierarchy(cause.inner_exception) unless cause.inner_exception.nil?
            end
        end
        
        def process_cause(cause)
            #TODO: reinstate this if possible...
            #output.push("[#{cause.inspect}]") 
            output.push("[#{cause.message}]") if cause.respond_to?(:message)
            output.push("[#{cause.body}]") if cause.respond_to?(:body)
        end
        
        def body()
            raise NotImplementedException, "This method is not implemented by the #{self.class} class", caller
        end
        
        private
        
        def format_exception(ex, error_message)
            return "Class:- #{ex.class}, Message:- #{ex.message} BackTrace:- #{ex.backtrace} Trace:- #{error_message} -"
        end
        
    end
end
