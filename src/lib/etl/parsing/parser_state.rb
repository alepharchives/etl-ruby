#!/usr/bin/env ruby

require 'rubygems'

include ETL

module ETL
    module Parsing

        class ParserState
            attr_reader :name
            attr_accessor :token

            def initialize( name )
                @state_transitions = {}
                @name = name
            end

            def accept( token )
                @state_transitions.each do |rule, sub_state|
                    if token =~ %r'^#{rule}$'
                        sub_state.token = token
                        return sub_state
                    end
                end
                return create_error_state( token )
            end
            
            def create_error_state( token )
                error_state = ErrorState.new
                error_state.accept( token )
                state_names = []
                @state_transitions.values.each { |state| 
                    state_names.push( state.name ) unless state_names.include?( state.name )
                }
                msg = "When in state #{@name}, expected to transition to states: #{state_names.join(' or ')}, but received: '#{token}'"
                error_state.message = msg
                return error_state
            end

            def add_transition( rule, sub_state )
                @state_transitions.store( rule, sub_state )
            end

            def error?
                false
            end

            def accepted?
                @state_transitions.empty?
            end
        end

        class ErrorState < ParserState
            attr_accessor :message
            
            def initialize
                super( :ERROR )
            end

            def accept( token )
                @token = token
                nil
            end

            def add_transition( rule, sub_state )
                ex = InvalidOperationException.new( 'the error state cannot accept sub-rules' )
                raise ex, ex.message, caller
            end

            def error?
                true
            end
            
        end

    end
end
