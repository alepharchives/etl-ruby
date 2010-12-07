#!/usr/bin/env ruby

require 'rubygems'
require 'singleton'

include ETL

module ETL
    module Parsing
        class Parser

            include Validation

            attr_accessor :name

            def initialize( grammar, scanner_opts={} )
                validate_arguments( binding() )
                @grammar = grammar
                @scanner_opts = scanner_opts
            end

            def parse( input )
                scanner = initialize_scanner( input.strip )
                current_state = @grammar.start_state
                parse_stack = [ current_state ]
                until scanner.eos?
                    token = scanner.next_token
                    current_state = current_state.accept( token )
                    parse_stack.push current_state
                    parser_error( input, parse_stack ) if current_state.error?
                end
                validate( binding() )
                return parse_stack
            end

            private

            ErrorData = Struct.new( "ErrorData", :raw_input, :states )

            def initialize_scanner( input )
                scanner = Scanner.new( input )
                scanner.options = @scanner_opts unless @scanner_opts.empty?
                scanner
            end

            def validate( binding_context )
                unless binding_context.current_state.accepted?
                    stack = binding_context.parse_stack
                    stack.push ErrorState.new
                    parser_error( binding_context.input, stack )
                end
            end

            def parser_error( input, parse_stack )
                error_data = ErrorData.new
                error_data.raw_input = input
                error_data.states = parse_stack
                message = 'empty transition hash'
                if error_data.states[error_data.states.size-1].respond_to? :message
                    message = error_data.states[error_data.states.size-1].message.nil? ?  '' : error_data.states[error_data.states.size-1].message
                end
                exception = ParseError.new( error_data, 'unable to parse input text: ' + message )
                raise exception, exception.message, caller
            end
        end
    end
end
