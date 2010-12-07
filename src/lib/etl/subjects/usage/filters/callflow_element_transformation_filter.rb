#!/usr/bin/env ruby

require 'rubygems'
require 'delegate'

include ETL
include ETL::Transformation
include ETL::Transformation::Pipeline::Filters

module ETL
    module Subjects
        module Usage
            module Filters
                class CallflowElementTransformationFilter
                    
                    mixin TransformationFilterSupport
                    
                    def initialize env
                        validate_arguments( binding() )
                        @environment = env
                        @transformer = StateTokenTransformer.new
                        @transformer.get(:date).from_state(:date)  { |input| input }
                        @transformer.get(:time).from_state(:time)  { |input| extract_service_invocation_time( input ) }
                        @transformer.get(:flow_id).from_state(:end) { |input|    
                            result = input.match(/Call Flow Execution Id=\(flow_exe:([\w,\d]{32})\)/)
                            coalesce_null( result[1].strip )
                        }
                        @transformer.get(:element_type).from_state(:end) { |input|    
                            result = input.match(/Element Type=\((\w*)\)/)
                            coalesce_null( result[1].strip )
                        }
                        @transformer.get(:script_start_date).from_state(:end) { |input|    
                            result = input.match(/Element Start Time=\(([\w,\s,\d,:,\-]*)\)/)
                            result = parse_date(result)
                            coalesce_null( result.to_s )
                        }
                        @transformer.get(:script_start_time).from_state(:end) { |input|    
                            result = input.match(/Element Start Time=\(([\w,\s,\d,:,\-]*)\)/)
                            result = Time.parse(result[1].strip)
                            coalesce_null( result.strftime("%H:%M:%S") )
                        }
                        @transformer.get(:script_end_date).from_state(:end) { |input|    
                            result = input.match(/Element End Time=\(([\w,\s,\d,:,\-]*)\)/)
                            result = parse_date(result)
                            coalesce_null( result.to_s )
                        }
                        @transformer.get(:script_end_time).from_state(:end) { |input|    
                            result = input.match(/Element End Time=\(([\w,\s,\d,:,\-]*)\)/)
                            result = Time.parse(result[1].strip)
                            coalesce_null( result.strftime("%H:%M:%S") )
                        }
                        @transformer.get(:app_uuid).from_state(:end) { |input|
                            result = input.match(/Application Id=\((.*)\)/)
                            coalesce_null( result[1] )
                        }
                        @transformer.get(:call_end_date).from_state(:end) { |input|    
                            result = input.match(/Call Start Time=\(([\w,\s,\d,:,\-]*)\)/)
                            result = parse_date(result)
                            coalesce_null( result.to_s )
                        }
                        @transformer.get(:call_end_time).from_state(:end) { |input|    
                            result = input.match(/Call Start Time=\(([\w,\s,\d,:,\-]*)\)/)
                            unless result.nil?
                                result = Time.parse(result[1].strip)
                                coalesce_null( result.strftime("%H:%M:%S") )
                            end
                        }
                        @transformer.get(:callee).from_state(:end) { |input|    
                            result = input.match(/Callee=\(([\+@\w\d:\.]*)\)/)
                            unless result.nil?
                                coalesce_null( result[1].strip )
                            end
                        }
                        @transformer.get(:connected).from_state(:end) { |input|    
                            result = input.match(/Connected=\((true|false)\)/)
                            connected = 'false'
                            connected = result[1].strip unless result.nil?
                            coalesce_null( connected )
                        }
                        @transformer.get(:duration).from_state(:end) { |input|    
                            result = input.match(/Duration=\((\d*)\)/)
                            duration = '0'
                            duration = result[1].strip unless result.nil?
                            coalesce_null( duration )
                        }
                    end              
                end
            end
        end
    end
end
