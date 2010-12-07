#!/usr/bin/env ruby

require 'rubygems'

include ETL

module ETL
    module Parsing
        class Grammar

            attr_reader :starting_state_name, :state_transition_table
            
            def Grammar.create( starting_state_name=:start, transition_tables=nil )
                return Grammar.new( starting_state_name ) { transition_tables }
            end

            def initialize( starting_state_name=:start )
                unless block_given?
                    raise ArgumentError, 'Grammar.new requires a block', caller
                end
                @state_transition_table = yield
                @starting_state_name = starting_state_name
            end

            def start_state
                @start_state ||= create_parser_state( @starting_state_name )
            end

            private

            def create_parser_state( state_name )
                state = ParserState.new state_name
                @state_transition_table[state_name].each do |rule, next_state|
                    state.add_transition(rule, create_parser_state(next_state))
                end
                state
            end
        end
    end
end
