#!/usr/bin/env ruby
 
require 'rubygems'

module ETL
    module Integration
        module Engine
            module Channels
                    
                #
                # This is the database error channel to insert error messages into database.
                #
                class DatabaseAuditChannel
                    
                    include Validation
                    
                    def initialize(database)
                        validate_arguments(binding())
                        @database = database
                        @processor = SqlCommandProcessor.new(database)
                    end
                    
                    def marshal(in_exchange)
                        message = in_exchange.inbound                        
                        sql = build_sql(message)
                        
                        command = Message.new
                        command.body = sql
                        out_exchange = Exchange.new( ctx = message.headers[:context] )
                        out_exchange.outbound = command
                        out_exchange = out_exchange.flip()

                        @processor.process(out_exchange)
                    end
                    
                    private 
                    def build_sql( message )
                        sql_arr = []
                        ctx = message.headers[:context]
                        message.headers.each do |key, value|
                            sql_arr << "INSERT INTO workflow_audit (event_id, field_type, field_key, field_value) VALUES ('#{ctx.object_id}', 'header', '#{key}', '#{value}')"
                        end
                        sql_arr << "INSERT INTO workflow_audit (event_id, field_type, field_key, field_value) VALUES ('#{ctx.object_id}', 'body', '#{message.body.class}', '#{message.body.inspect}');"
                        
                        return sql_arr.join(';')
                    end
                    
                end
            end
        end
    end
end