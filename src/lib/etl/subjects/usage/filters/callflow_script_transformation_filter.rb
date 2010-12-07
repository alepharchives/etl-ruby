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
                class CallflowScriptTransformationFilter
                    
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
                        @transformer.get(:execution_type).from_state(:end) { |input|    
                            result = input.match(/Script Execution Type=\((\w*)\)/)
                            coalesce_null( result[1].strip )
                        }
                        @transformer.get(:script_start_date).from_state(:end) { |input|    
                            result = input.match(/Script Start Time=\(([\w,\s,\d,:,-]*)\)/)
                            result = Date.parse(result[1].strip)
                            coalesce_null( result.to_s )
                        }
                        @transformer.get(:script_start_time).from_state(:end) { |input|    
                            result = input.match(/Script Start Time=\(([\w,\s,\d,:,-]*)\)/)
                            result = Time.parse(result[1].strip)
                            coalesce_null( result.strftime("%H:%M:%S") )
                        }
                        @transformer.get(:caller).from_state(:end) { |input|    
                            result = input.match(/Caller=\(([\+@\w,\d,:,\.]*)\)/)
                            coalesce_null( result[1].strip )
                        }
                        @transformer.get(:callee).from_state(:end) { |input|    
                            result = input.match(/Callee=\(([\+@\w,\d,:,\.]*)\)/)
                            coalesce_null( result[1].strip )
                        }
                         @transformer.get(:duration).from_state(:end) { |input|    
                            result = input.match(/Duration=\((\d*)\)/)
                            coalesce_null( result[1].strip )
                        }
                        @transformer.get(:app_uuid).from_state(:end) { |input|
                            result = input.match(/Application Id=\((.*)\)/)
                            coalesce_null( result[1] )
                        }
                    end
                end
            end
        end
    end
end
