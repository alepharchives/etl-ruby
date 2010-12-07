#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Processors
                # A specialized processor that deals with the construction 
                # and/or execution of SQL statements.
                class SqlCommandProcessor < Processor
                    
                    include Validation
                    
                    def initialize(database)
                        super( :response => '${response}' )
                        validate_arguments(binding())
                        @database = database
                    end
                    
                    def do_process(exchange)
                        command_text = exchange.inbound.body
                        on_invalid_payload(exchange, "The message has no body.") if command_text.nil?
                        begin
                            @database.connect()
                            params = extract_parameters(exchange.inbound.headers[:params])
                            command = @database.create_command(command_text)
                            @response = get_command_response(command, params)
                        rescue Exception => ex
                            @options[:fault_code] = FaultCodes::SqlError
                            raise #rethrow
                        ensure
                            @database.disconnect() if @database.connected?
                        end
                    end
                    
                    def get_command_response(command, params)
                        command.execute(*params)
                    end
                    
                    def extract_parameters(parameters)
                        parameters unless parameters.nil?
                    end
                end
            end
        end
    end
end
