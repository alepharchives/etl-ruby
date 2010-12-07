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
                class MessagingTransformationFilter
                    
                    mixin TransformationFilterSupport
                    
                    def initialize env
                        validate_arguments( binding() )
                        @environment = env
                        
                        @regexFrom = '[^,]*'
                        @regexGroupId = '[A-Za-z0-9]*'
                        @regexProvider='[A-Za-z]'
                        
                        @transformer = StateTokenTransformer.new
                        @transformer.get(:date).from_state(:date) { |input| input }
                        @transformer.get(:time).from_state(:time) { 
                            |input| extract_service_invocation_time( input ) 
                        }
                        @transformer.get(:txn_id).from_state(:txn_id) { |input|
                            result = input.match(/\[(.*)\]/)
                            if result.nil?
                                'NULL'
                            else
                                coalesce_null( result[1] ) 
                            end
                        }
                        @transformer.get(:app_uuid).from_state(:app_uuid) { |input|
                            result = input.match(/\[(.*)\]/)
                            coalesce_null( result[1] )
                        }
                        @transformer.get(:recipient_uris).from_state(:end) { |input|    
                            result = input.match(/continueSendMessage\(\[(.*)\].*/)

                            if result.nil?
                                result = input.match(/continueSendMessage\(recipients\s\[\[(.*)\]\],\sprovider.*/)
                            end

                            if result.nil?
                                result = input.match(/continueSendMessage\(recipients\s\[\[(.*)\]\],\sfrom.*/)
                            end
                            if result.nil?
                                result = input.match(/com.xx.capabilities.(messaging|sms).SmsClient.sendToPlatform\(\[\[(.*)\],.*/)
                            end

                            coalesce_null( result[result.length-1].strip )
                        }
                        @transformer.get(:from).from_state(:end) { |input|
                            result = input.match(/continueSendMessage\(\[.*\],\s(#{@regexFrom}),.*/u)
                            if result.nil?
                                result = input.match(/continueSendMessage\(recipients\s\[\[.*\]\],\sprovider\s\[\[\s.*\]\],\sgroupId\s\[#{@regexGroupId}\],\soneway\s\[(true|false)\],\sfrom\s\[(#{@regexFrom})\],.*/)
                            end
                            if result.nil?
                                result = input.match(/continueSendMessage\(recipients\s\[\[.*\]\],\sfrom\s\[(#{@regexFrom})\],.*/)
                            end
                            if result.nil?
                                result = input.match(/com.xx.capabilities.(messaging|sms).SmsClient.sendToPlatform\(\[\[.*\],\s(#{@regexFrom}),.*/)
                            end
                            if result.nil?
                                result = "NULL".match("NULL")
                            end
                            coalesce_null( result[result.length-1].strip )
                        }
                        @transformer.get(:providers).from_state(:end) { |input|
                            result = input.match(/continueSendMessage\(recipients\s\[\[.*\]\],\sfrom\s\[#{@regexFrom}\],\sprovider\s\[\[(.*)\]\],.*/)
                            if result.nil?
                                result = input.match(/continueSendMessage\(recipients\s\[\[.*\]\],\sprovider\s\[\[(.*)\]\],.*/)
                            end
                            if result.nil?
                                result = "NULL".match("NULL")
                            end
                            coalesce_null( result[result.length-1].strip )
                        }
                        @transformer.get(:message_id).from_state(:end) { |input|
                            result = input.match(/continueSendMessage\(\[.*\],\s#{@regexFrom},\s(#{@regexGroupId}).*/)
                            if result.nil?
                                result = input.match(/continueSendMessage\(recipients\s\[\[.*\]\],\sprovider\s\[\[\s.*\]\],\sgroupId\s\[(#{@regexGroupId})\],.*/)
                            end
                            if result.nil?
                                result = input.match(/continueSendMessage\(recipients\s\[\[.*\]\],\sfrom\s\[#{@regexFrom}\],\sprovider\s\[\[.*\]\],\sgroupId\s\[(#{@regexGroupId})\],.*/)
                            end
                            if result.nil?
                                result = input.match(/continueSendMessage\(recipients\s\[\[.*\]\],\sfrom\s\[#{@regexFrom}\],\sgroupId\s\[(#{@regexGroupId})\],.*/)
                            end
                            if result.nil?
                                'NULL'
                            else
                                coalesce_null( result[1].strip )
                            end
                        }
                        @transformer.get(:message_text).from_state(:end) { |input|
                            coalesce_null( "NULL" )
                        }
                        @transformer.get(:oneway).from_state(:end) { |input|
                            result = input.match(/continueSendMessage\(\[.*\],\s#{@regexFrom},\s#{@regexGroupId},\s.*,\s(true|false),\s.*/)
                            if result.nil?
                                result = input.match(/continueSendMessage\(recipients\s\[\[.*\]\],\sprovider\s\[\[\s.*\]\],\sgroupId\s\[(#{@regexGroupId})\],\soneway\s\[(true|false)\],.*/)
                            end
                            if result.nil?
                                result = input.match(/continueSendMessage\(recipients\s\[\[.*\]\],\sfrom\s\[#{@regexFrom}\],\sprovider\s\[\[.*\]\],\sgroupId\s\[#{@regexGroupId}\],\smessage\s\[.*\],\soneway\s\[(true|false)\],\s.*/)
                            end
                            if result.nil?
                                result = input.match(/continueSendMessage\(recipients\s\[\[.*\]\],\sfrom\s\[#{@regexFrom}\],\sgroupId\s\[#{@regexGroupId}\],\smessage\s\[.*\],\soneway\s\[(true|false)\],\s.*/)
                            end
                            if result.nil?
                                result = input.match(/com.xx.capabilities.(messaging|sms).SmsClient.sendToPlatform\(\[\[.*\],\s#{@regexFrom},\s.*,\s(true|false).*/)
                            end
                            if result.nil?
                                result = "true".match(/true/)
                            end
                            coalesce_null( result[result.length-1].strip )
                        }
                    end
                end
            end
        end
    end
end
