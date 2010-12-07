#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Processors
                # A processor that deals with parsing log line inputs.
                class ParserProcessor < Processor
                    
                    include Validation
                    
                    def initialize( grammar_file_uri )
                        validate_arguments(binding())
                        super( :fault_code => FaultCodes::ParserError )
                        @grammar_file_uri = grammar_file_uri
                    end
                   
                    protected
                    def do_process(exchange)                
                        parser = ParserFactory.get_parser( @grammar_file_uri.evaluate(exchange) )
                        parse_stack = parser.parse(exchange.inbound.body)
                        
                        response = Message.new
                        response.body = parse_stack
                        exchange.outbound = response
                    end
                end
            end
        end
    end
end
