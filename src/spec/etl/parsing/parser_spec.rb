#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'

include BehaviourSupport
include ETL::Parsing

describe given( Parser ), 'when parsing log data' do

    it 'should explode if the starting state name is nil' do
        lambda { Parser.new( nil, {} ) }.should raise_error( ArgumentError, "the 'grammar' argument cannot be nil" )
    end

    it 'should explode if the grammar is nil' do
        lambda { Parser.new( :foo, nil ) }.should raise_error( ArgumentError, "the 'scanner opts' argument cannot be nil" )
    end

    it 'should read from the scanner until eos' do
        grammar = mock( 'grammar-stub' )
        scanner = mock( 'scanner-stub' )
        state = mock( 'state-stub' )

        Scanner.stub!( :new ).and_return( scanner )
        grammar.should_receive( :start_state ).once.and_return( state )
        scanner.should_receive( :eos? ).once.and_return( true )
        state.should_receive( :accepted? ).once.and_return( true )

        parser = Parser.new( grammar )
        parser.parse( 'foo bar baz buz bug bog bag bye!' ).should have( 1 ).items
    end

    it 'should continue shifting states and reducing rules until eos' do

        #todo: reconsider this test, as it feels a little fragile!

        grammar = mock( 'grammar' )
        scanner = mock( 'scanner' )
        start_state = mock( 'start-state' )
        transition_state = mock( 'transition-state' )
        end_state = mock( 'end-state' )
        Scanner.stub!( :new ).and_return( scanner )

        run  = 0
        scanner.should_receive( :eos? ).exactly( 3 ).times do
            run += 1
            run >= 3
        end

        scanner.should_receive( :next_token ).at_least( 1 ).times.and_return( 'ignored!' )
        grammar.should_receive( :start_state ).once.and_return( start_state )
        start_state.should_receive( :accept ).once.and_return( transition_state )
        transition_state.should_receive( :accept ).once.and_return( end_state )
        transition_state.should_receive( :error? ).once.and_return( false )
        end_state.should_receive( :error? ).once.and_return( false )
        end_state.should_receive( :accepted? ).once.and_return( true )

        parser = Parser.new( grammar )
        parser.parse( 'the quick brown fox, etc, etc, etc' ).should have( 3 ).items
    end

    it 'should raise and error when a state transition fails' do
        grammar = mock( 'grammar2' )
        scanner = mock( 'scanner2' )
        start_state = mock( 'start_state' )
        error_state = mock( 'error_state' )

        Scanner.stub!( :new ).and_return( scanner )
        grammar.should_receive( :start_state ).and_return( start_state )
        scanner.should_receive( :eos? ).and_return( false )
        scanner.should_receive( :next_token ).and_return( 'ignored!' )
        start_state.should_receive( :accept ).once.and_return( error_state )
        error_state.should_receive( :error? ).once.and_return( true )

        lambda {
            parser = Parser.new( grammar )
            parser.parse( 'goo gar gaz gab gob goh' )
        }.should raise_error( ParseError, 'unable to parse input text: empty transition hash' )
    end
end
