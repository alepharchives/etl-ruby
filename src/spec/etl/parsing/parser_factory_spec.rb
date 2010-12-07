#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'

include BehaviourSupport
include ETL::Parsing

describe given( ParserFactory ) do

    before :each do
        @file_uri = "mock_grammar.grammar"
        @grammar_str = "grammar_def = {:transitions => { :start => { } }, :delimiters => {/a/, /b/} }"
        @grammar_def = {
            :transitions => { :start => { } }, 
            :delimiters => {/a/, /b/} 
        }
        @mock_grammar = mock( "grammar" )
        @mock_parser = mock( 'parser' )        
    end
    
    it "should create a parser with a grammar given a grammar file uri" do
        # expectations
        ::IO.should_receive( :read ).with( @file_uri ).and_return( @grammar_str )
        ParserFactory.should_receive( :eval ).with( @grammar_str ).and_return( @grammar_def )
        Grammar.should_receive( :create ).with( :start, @grammar_def[ :transitions ] ).and_return( @mock_grammar )        
        expected_delim = { :custom_delimiters => @grammar_def[:delimiters] }
        Parser.should_receive( :new ).with( @mock_grammar, expected_delim ).and_return( @mock_parser )    

        # act and assert
        ParserFactory.get_parser( @file_uri ).should equal( @mock_parser )
    end
    
    it "should cache parser instances for the same grammar files" do
        # prepare
        ::IO.stub!( :read ).and_return( @grammar_str )
        ParserFactory.stub!( :eval ).and_return( @grammar_def )
        
        # expectations
        Grammar.should_receive( :create ).twice.and_return( @mock_grammar )        
        
        # act
        ParserFactory.get_parser( 'some_uri' );
        ParserFactory.get_parser( 'other_uri' );
        ParserFactory.get_parser( 'some_uri' );
        ParserFactory.get_parser( 'other_uri' );

    end
end