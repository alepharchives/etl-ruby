# #!/usr/bin/env ruby

require 'rubygems'
require 'delegate'

include ETL
include ETL::Transformation
include ETL::Transformation::Pipeline::Filters

module ETL
    module Subjects
        module Usage
            module Filters
                class NewSessionTransformationFilter

                    mixin TransformationFilterSupport

                    def initialize env
                        validate_arguments( binding() )
                        @environment = env
                        @transformer = StateTokenTransformer.new
                        @transformer.get(:date).from_state(:date) { |input| input }
                        @transformer.get(:time).from_state(:time) { |input| extract_service_invocation_time( input ) }
                        @transformer.get(:cert_guid).from_state(:end) { |input|
                            #todo: don't strip urn:uuid off the field...
                            result = input.match(/Application Id=\((.*)\)/)
                            coalesce_null( result[1] )
                        }
                        @transformer.get(:caller_number).from_state(:end) { |input|
                            result = input.match(/Caller Telno=\((?:[\w]{3}\:{1})?([^\)]*)?(;(.)*)*\)/)
                            coalesce_null( result[1] )
                        }
                        @transformer.get(:caller_endpoint_kind).from_state(:end) do |input|
                            result = input.match(/Caller Telno=\(([^\)]*)\)/)
                            extract_endpoint_kind( result[1] )
                        end
                        @transformer.get(:callee_number).from_state(:end) { |input|
                            result = input.match(/Callee Telno=\((?:[\w]{3}\:{1})?([^\)]*)?(;(.)*)*\)/)
                            coalesce_null( result[1] )
                        }
                        @transformer.get(:callee_endpoint_kind).from_state(:end) do |input|
                            result = input.match(/Callee Telno=\(([^\)]*)\)/)
                            endpoint = result[1]
                            extract_endpoint_kind( result[1] )
                        end
                        @transformer.get(:call_start_time).from_state(:end) { |input|
                            matchRes = input.match(/Call Start Time=\(([^\)]*)\)/)
                            coalesce_null( matchRes[1] )
                        }
                        @transformer.get(:call_duration).from_state(:end) { |input|
                            matchRes = input.match(/Call Duration=\(([^\)]*)\)/)
                            coalesce_null( matchRes[1] )
                        }
                        @transformer.get(:call_termination_cause).from_state(:end) { |input|
                            matchRes = input.match(/Call Termination Cause=\(([^\)]*)\)/)
                            coalesce_null( matchRes[1] )
                        }
                        @transformer.get(:trans_id).from_state(:end) { |input| 'NULL' }
                    end
                end
            end
        end
    end
end
