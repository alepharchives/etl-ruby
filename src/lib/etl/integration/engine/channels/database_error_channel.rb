#!/usr/bin/env ruby
 
require 'rubygems'

module ETL
    module Integration
        module Engine
            module Channels
                    
                #
                # This is the database error channel to insert error messages into database.
                #
                class DatabaseErrorChannel
                    
                    include Validation
                    
                    def initialize(database)
                        #TODO: fix this as it should take a context and figure out which database to use
                        validate_arguments(binding())
                        @database = database
                        @processor = SqlCommandProcessor.new(database)
                    end
                    
                    def marshal(exchange)
                        message = exchange.inbound
                        sql = build_error_sql(message)
                        exchange_out = create_exchange(sql, message.headers[:context])
                        @processor.process(exchange_out)
                    end
                    
                    private

                    def build_error_sql(message)
                        exception = message.headers[:exception]
                        error_text = (exception.respond_to?(:process_body)) ? exception.process_body() : exception.message
                        fault_code = message.headers[:fault_code]
                        fault_description = message.headers[:fault_description]
                        "INSERT INTO errors (error_text, fault_code, fault_description) VALUES ('#{error_text}', '#{fault_code}', '#{fault_description}')"
                    end
                    
                    def create_exchange(sql, context)
                        command = Message.new
                        command.body = sql                        
                        exchange = Exchange.new(context)
                        exchange.outbound = command
                        return exchange.flip()
                    end

                end
            end
        end
    end
end
