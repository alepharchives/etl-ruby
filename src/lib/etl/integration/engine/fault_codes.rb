#!/usr/bin/env ruby
 
module ETL
    module Integration
	module Engine
	    
	    # Maintains a set of constant fault codes and static (e.g. not for
            # translation) error messages.
	    module FaultCodes
		
		[ 
                    :missing_message_body, 
                    :routing_error, 
                    :unhandled_exception, 
                    :parser_error,
                    :transformer_error,
                    :sql_error,
                    :invalid_payload
                ].each do |fault_code|
		    const_set( fault_code.to_s.camelize.to_sym, fault_code )
                end
		
		msg=<<-EOS
		    All ETL::Integration::Engine exceptions MUST be a subclass of ExecutionException (at least indirectly)
		EOS
		
		InvalidLayerExceptionMessage=msg.chop.chomp		
		
	    end
	end
    end
end
