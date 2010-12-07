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
                class UsageTransformationFilter

                    mixin TransformationFilterSupport

                    def initialize( env )
                        validate_arguments binding()
                        @environment = env
                        @transformer = StateTokenTransformer.new
                        @transformer.get(:date).from_state(:date) { |input| input }
                        @transformer.get(:time).from_state(:time) { |input| input }
                        @transformer.get(:trans_id).from_state(:path1_trans_id, :path2_trans_id, :path3_trans_id) { |input| coalesce_null( input[1, input.size()-2] ) }
                        @transformer.get(:cert_guid).from_state(:path1_app_uuid, :path2_app_uuid, :path3_app_uuid, :path4_app_uuid) { |input|
                            coalesce_null( content = input[1, input.size()-2] )
                            #content.sub(/urn:uuid:/, '')
                        }
                        @transformer.get(:service).from_state(:path1_capability_name, :path2_capability_name, :path3_capability_name) { |input| 
                            input = input[1, input.size()-2]
                            if input.include?('.')
                                result = input.match(/\.([^\.]*)$/)
                                coalesce_null( result[1] )
                            else
                                coalesce_null( input )
                            end
                        }
                        @transformer.get(:method).from_state(:capability_method) { |input|
                            result = input.match(/\.(\w+):/)
                            result[1]
                        }
                        @transformer.get(:time_to_complete).from_state(:ms) { |input| input }
                    end
                end
            end
        end
    end
end
