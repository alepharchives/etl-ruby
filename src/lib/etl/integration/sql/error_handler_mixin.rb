#!/usr/bin/env ruby
 
require 'rubygems'

module ETL
    module Integration
        module SQL
            module ErrorHandlerMixin
                
                def on_data_access_error( exception_object=$ERROR_INFO, driver=nil )
                    on_sys_call_error( exception_object ) if exception_object.kind_of?(SystemCallError)
                    
                    ex_info = launder_exception_info( exception_object )
                    message = "#{ex_info.error_code.to_s}: #{ex_info.message}"
                    raise_exception( message, exception_object, ex_info )
                end
                
                def on_connect_error( exception_object=$ERROR_INFO, driver=nil )
                    default_severity = :FATAL
                    data_source_uri = if driver.respond_to?( :connection_string ) 
                        driver.connection_string
                    else
                        String::Empty
                    end
                    ex_info = launder_exception_info( exception_object )
                    message = "#{( ex_info.error_code == :UNKNOWN ) ?
                        'FATAL ERROR' : ex_info.error_code.to_s}: unable to establish connection. #{ex_info.message}"
                    raise ConnectivityException.new( data_source_uri, message, exception_object, 
                        default_severity, ex_info.error_code ), message, caller
                end
                
                def on_sys_call_error( exception_object=$ERROR_INFO )
                    ex_info = launder_exception_info( exception_object )
                    ex_info.severity = :FATAL
                    message = "#{ex_info.error_code.to_s} (#{ex_info.severity}): #{exception_object.class}: #{exception_object.message}"
                    raise_exception( message, exception_object, ex_info )
                end
                
                private
                
                def raise_exception( message, exception_object, ex_info )
                    raise DataAccessException.new( message, exception_object, ex_info.severity, 
                        ex_info.error_code ), message, caller                    
                end
                
                DataAccessExceptionInfo = Struct.new( "DataAccessExceptionInfo", :message, :severity, :error_code )
                
                def launder_exception_info( exception_object )
                    ex_info = default_error_info( exception_object )                   
                    return ex_info unless exception_object.respond_to?( :message )
                    
                    message_match = exception_object.message.match( /(ERROR|FATAL|WARNING)(?:[\s]+)([\w]*)(?:[\s]+)(.*)/ )
                    if message_match.nil?
                        ex_info.message = exception_object.message
                        return ex_info
                    end
                    [ :severity, :error_code, :message ].each_with_index do |error_part, index|
                        error_data = message_match[ index + 1 ]
                        if error_part == :message
                            error_data = extract_system_message_from_error_description( error_data )
                        else
                            error_data = error_data.to_sym 
                        end
                        ex_info.send( "#{error_part}=".to_sym, error_data )
                    end
                    return ex_info
                end
                
                def extract_system_message_from_error_description( error_data )
                    sys_message_match = error_data.match( /(?:[M]{1})(.*)(?=([\s]+)(?:[FP]))/ )
                    return error_data if sys_message_match.nil?
                    return sys_message_match[1].rstrip
                end
                
                def default_error_info( exception_object )
                    DataAccessExceptionInfo.new( ( $! || exception_object.to_s ), :UNKNOWN, :UNKNOWN )
                end
                
            end
        end
    end
end
