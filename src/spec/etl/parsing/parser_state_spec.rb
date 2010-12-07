#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'

include BehaviourSupport
include ETL::Parsing

describe given( ParserState ), 'when constructing a parser state transition graph' do

    it 'should not be in the error state' do
        ParserState.new( 'foo' ).should_not be_error
    end

    it 'should not be in the accepted state if it has any transitions' do
        state = ParserState.new( 'foo' )
        state.add_transition( //, ParserState.new( 'bar' ) )
        state.should_not be_accepted
    end

    it 'should return the error state if a supplied token fails to match any rules' do
        state = ParserState.new( 'foo' )
        digits_only_rule = /\d*/
        state.add_transition( digits_only_rule, ParserState.new( 'bar' ) )
        state.accept( 'no-digits-here!' ).should be_error
    end
    
    it 'should return the error state with a corrent message if a supplied token fails to match any rules' do
        state = ParserState.new( 'foo' )
        digits_only_rule = /\d*/
        blah_rule = /blah/
        state.add_transition( digits_only_rule, ParserState.new( 'digits' ) )
        state.add_transition( blah_rule, ParserState.new( 'blah' ) )
        state.accept( 'invalid_token!' ).message.should eql("When in state foo, expected to transition to states: blah or digits, but received: 'invalid_token!'")
    end

    it 'should return a valid sub-state if the given token matches a rule' do
        state = ParserState.new( 'foo' )
        single_word_rule = /\w+/
        state.add_transition( single_word_rule, ParserState.new( 'accepted' ) )
        state.accept( 'WORD' ).should be_accepted
    end

end

describe given( ErrorState ), 'when representing the parse-error state' do

    it 'should always be in the error state' do
        ErrorState.new.should be_error
    end

    it 'should always be named using the :ERROR symbol' do
        first = ErrorState.new
        second = ErrorState.new
        first.name.object_id.should eql( second.name.object_id )
    end

    it 'should always accept a token and return nil' do
        state = ErrorState.new
        [ 'foo', 12345, nil, 'bar', /what!?/ ].each do |nonsense_token|
            state.accept( nonsense_token ).should be_nil
            state.token.should == nonsense_token
        end
    end

    it 'should explode if you try to add a state transition' do
        lambda {
            ErrorState.new.add_transition( /foo/, ParserState.new( 'foo' ) )
        }.should raise_error( InvalidOperationException, 'the error state cannot accept sub-rules' )
    end

end
