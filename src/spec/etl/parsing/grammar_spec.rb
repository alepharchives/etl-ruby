#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'

include BehaviourSupport
include ETL::Parsing

module GrammarCustomMatchBehaviours
    class TransitionToMatcher
        initialize_with :expected_state, :rule, :validate => true

        def matches? target
            @target = target
            actual_state = GrammarCustomMatchBehaviours.get_state_transition_table( @target ).fetch( @rule, nil )
            return actual_state.eql?( @expected_state )
        end
        def failure_message
            informational_message negate=false
        end
        def negative_failure_message
            informational_message negate=true
        end

        private
        def informational_message negate
            "expected #{@target.name} #{( negate ) ? 'not' : ''} to transition to state #{@expected_state.name} via rule /#{@rule.source}/"
        end
    end

    def transition_to( expected_state, rule )
        return TransitionToMatcher.new( expected_state, rule )
    end

    def GrammarCustomMatchBehaviours.get_state_transition_table( state )
        state.instance_variable_get( '@state_transitions' )
    end
end

describe given( Grammar ), 'when constructing a state transition table from a given grammar' do

    include GrammarCustomMatchBehaviours

    it 'should explode unless a block is given!' do
        lambda { Grammar.new }.should raise_error( ArgumentError, 'Grammar.new requires a block' )
    end

    it 'should create a transition for each given state in the supplied hash table' do
        transition_table = {
            :start => {
                /bar/ => :bar
            },
            :bar => {
                /baz/ => :baz
            },
            :baz => {
                /buz/ => :buz
            },
            :buz => {}
        }

        grammar = Grammar.new( :start ) { transition_table }

        state = grammar.start_state
        test_transitions( state, :start, transition_table[ :start ] )
        transition_table.each do |key, value|
            state = test_transitions( state, key, value ) unless state.name == :start
        end

    end

    #it 'should create multiple sub-state(s) for a multi-key transition' do
    #    transition_table = {
    #        :start => {
    #            /foo/ => :end,
    #            /bar/ => :end
    #        },
    #        :end => {}
    #    }
    #
    #    grammar = Grammar.new( :start ) { transition_table }
    #
    #    state = grammar.start_state
    #    transitions = GrammarCustomMatchBehaviours.get_state_transition_table state
    #    transitions.each do |key, value|
    #        value.should transition_to( state, %r'#{key}' )
    #    end
    #end

    def test_transitions( state, key, value )
        state.name.should eql( key )
        transitions = GrammarCustomMatchBehaviours.get_state_transition_table state
        return state if transitions.nil?
        transition_pattern = transitions.to_a.first.first
        state = transitions[ transition_pattern ]
        state.name.should eql(value.to_a.first.second)
        return state
    end

end
