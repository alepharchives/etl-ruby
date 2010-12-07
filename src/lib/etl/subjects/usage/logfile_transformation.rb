#!/usr/bin/env ruby

require 'rubygems'
require 'date'

module ETL
    module Subjects
        module Usage
            
            # I am a transformation for inbound logfile data.
            # 
            #
            class LogfileTransformation
                
                mixin Validation
                
                def transform( environment, usage_type, file_uri )
                    validate_transform_arguments( environment, usage_type, file_uri )

                    output_uri = File.join( $config.dump_dir, lookup_usage_type_schema_mapping( usage_type ) )
                    filters = load_session_filters( usage_type, file_uri, environment )
                    
                    File.open( "#{output_uri}.errors", mode='a' ) do |error_io_buffer|
                        error_handling_decorator_filter = create_error_handling_decorator( filters.parsing_filter, 
                            environment, error_io_buffer )
                        conversion_filters = [
                            error_handling_decorator_filter,
                            filters.transformation_filter
                        ]
                        delegate_transformer = FileFilterChainTransformation.new(  
                            *( filters.entry_filters + conversion_filters )
                        )
                        delegate_transformer.transform( file_uri, output_uri )                        
                    end
                end
                
                private 

                def validate_transform_arguments( environment, usage_type, file_uri )
                    validate_arguments( binding() )
                end                
                
                @@required_filters = [:entry_filters, :parsing_filter, :transformation_filter]
                SessionFilters = Struct.new( "SessionFilters", *@@required_filters )

                def lookup_filter_factory( usage_type )
                    eval( "#{usage_type.to_s.camelize}FilterFactory" ) rescue nil
                end
                
                def load_session_filters( usage_type, file_uri, environment )
                    log_date = extract_log_date_from_file_uri( file_uri )
                    factory = lookup_filter_factory( usage_type ).new( environment )
                    filters = SessionFilters.new
                    @@required_filters.each do |filter_property|
                        filters.send( "#{filter_property}=".to_sym, factory.send( "get_#{filter_property}", log_date ) )
                    end
                    return filters
                end
                
                def create_error_handling_decorator( parsing_filter, environment, output_buffer )
                    DecoratorFilter.new( parsing_filter ) do |target_filter, input, filter_chain|
                        begin
                            target_filter.filter( input, filter_chain )
                        rescue FilterException => ex
                            raise ex unless ex.cause.kind_of?(ParseError)
                            error_data = ex.cause.error_data
                            output_buffer.puts [
                                "START-ERROR-INFO: ",
                                "[timestamp: '#{Time.now}']",
                                "[environment: '#{environment}']",
                                "[details: Filter '#{ex.filter}' encountered error '#{ex.inspect}']",
                                "[error-message: '#{error_data.states.last.message}']"
                            ].join( '' )
                            output_buffer.puts error_data.raw_input
                            output_buffer.puts "END-ERROR-INFO"
                        end
                    end
                end
             
                def extract_log_date_from_file_uri( file_uri )
                    date_string = file_uri[ /[\d]{4}-[\d]{2}-[\d]{2}/ ]
                    return Date.parse( date_string )
                end
                
                def lookup_usage_type_schema_mapping( usage_type )
                    return "#{usage_type}_raw.dump" if $config.log_file_subjects.include? usage_type.to_sym
                    raise InvalidOperationException, 'the supplied usage type is invalid', caller
                end
                
            end
        end
    end
end
