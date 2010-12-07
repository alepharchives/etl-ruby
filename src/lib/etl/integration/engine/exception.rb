#!/usr/bin/env ruby
 
require 'rubygems'

module ETL
    module Integration
        module Engine
            
	    # This exception type is reserved for errors that occur during workflow execution.
	    # All layer exceptions *must* inherit from this one (something that is actually enforced
	    # by the #MIS::Engine module in code).
	    class ExecutionException < StandardError	
                attr_reader :context, :message, :cause
                def initialize(context=nil, message=$!, cause=$ERROR_INFO)
                    @context, @message, @cause = context, message, cause
                end
                alias inner_exception cause
            end
            
            # An exception raised when the payload of a #Message or #Exchange is invalid for
            # the current execution context (e.g. the #Exchange does not contain any messages in
            # the expected channel (or channels) or the message is missing required headers (or body).
            class InvalidPayloadException < ExecutionException
                attr_reader :exchange
                def initialize(context, exchange, message=$!, cause=$ERROR_INFO)
                    super(context, message, cause)
                    @exchange = exchange
                end
            end
            
            # An exception raised when a service lookup fails. This exception is analogous to the
            # <code>UnresolvableUriException</code> in some respects, but has a less specific meaning. 
            class ServiceNotFoundException < ExecutionException
                initialize_with :message, :context, :uri, :attr_reader => true
            end
            
            # An exception raised whenever #Endpoint registration fails for some reason. 
            # The <code>context</code>, <code>endpoint</code> and details are all supplied.
            class EndpointRegistrationException < ExecutionException
                attr_reader :endpoint, :uri
                def initialize(context=nil, message=$!, endpoint=nil, uri="Unknown uri.", cause=nil)
                    super(context, message, cause)
                    auto_assign(binding(), :endpoint, :uri)
                end
            end
            
        end
    end
end
