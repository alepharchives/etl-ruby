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
                class ApplicationRegistrationTransformationFilter
                    
                    mixin TransformationFilterSupport
                    
                    def initialize env
                        validate_arguments( binding() )
                        @environment = env
                        @transformer = StateTokenTransformer.new
                        @transformer.get(:date).from_state(:date)  { |input| input }
                        @transformer.get(:time).from_state(:time) { 
                            |input| extract_service_invocation_time( input ) 
                        }
                        @transformer.get(:txn_id).from_state(:txn_id) { |input|
                            result = input.match(/\[(.*)\]/)
                            return_null_if_nil_result(result, 1)
                        }
                        @transformer.get(:app_id).from_state(:end) { |input|
                            result = input.match(/com.xx.security.applicationreg.ApplicationRegistrationInterface.\w+\(\[((urn:uuid:)?.{8}-.{4}-.{4}-.{4}-.{12}|sip:[\w,\d,_]+@[\w\d\._-]+)/)
                            coalesce_null( result[1] ) 
                        }
                        @transformer.get(:action).from_state(:end) { |input|
                            result = input.match(/com.xx.security.applicationreg.ApplicationRegistrationInterface.(\w+)\(/)
                            coalesce_null( result[1] ) 
                        }
                        @transformer.get(:action_comment).from_state(:end) { |input|
                           result = input.match(/com.xx.security.applicationreg.ApplicationRegistrationInterface.\w+\(\[((urn:uuid:)?.{8}-.{4}-.{4}-.{4}-.{12}|sip:[\w,\d,_]+@[\w\d\._-]+)(, )?([\w,\d,\s,\+,\.,\/,=,%,-]*)(\]\)){0,1}/)
                           value = return_null_if_nil_result(result, 4)
                           if value.size > 64
                               value = value[0,64]
                           end
                           value
                        }
                    end
                    

                end
            end
        end
    end
end
