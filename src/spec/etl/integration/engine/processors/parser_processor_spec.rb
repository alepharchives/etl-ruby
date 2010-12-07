#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine
include MIS::Framework

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Processors::ParserProcessor ) do

    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = ParserProcessor
        @constructor_args = [ 'grammar_file_uri' ]
    end

    before :each do
        @msg = Message.new
        @msg.body = "foo bar baz"
        @exchange = Exchange.new(dummy)
        @exchange.inbound = @msg
        @mock_parser = mock 'parser'
    end

    it "should call the parser factory with the correct grammar file" do
        # prepare
        dummy_parser = dummy
        grammar_file_uri = 'grammar file uri'
        # expectations
        ParserFactory.should_receive(:get_parser).and_return(dummy_parser)
        # act
        ParserProcessor.new( grammar_file_uri ).process(dummy("dummy exchange"))
    end

    it "should call the parser parse method with a received message" do
        # prepare
        ParserFactory.stub!( :get_parser ).and_return( @mock_parser )

        # expectations
        @mock_parser.should_receive(:parse).once.with( @msg.body )

        # act
        ParserProcessor.new( 'grammar' ).process( @exchange )
    end

    it "should put the parser output into the body of the response" do
        # prepare
        ParserFactory.stub!( :get_parser ).and_return( @mock_parser )
        parse_stack = %w[this is the parse stack!]
        @mock_parser.stub!(:parse).and_return(parse_stack)

        # act
        ParserProcessor.new( 'grammar' ).process( @exchange )
        # assert
        @exchange.outbound.body.should equal(parse_stack)
    end

    it "should raise a fault if the parser fails" do
        # prepare
        ParserFactory.stub!( :get_parser ).and_return( @mock_parser )        
        error_message = "Parsing failed..."
        exception = ETL::Parsing::ParseError.new(nil, error_message)      
        @mock_parser.stub!(:parse).and_raise exception

        processor = ParserProcessor.new( 'grammar' )

        expected_fault = Message.new
        expected_fault.set_header(:fault_code, FaultCodes::ParserError)
        expected_fault.set_header(:fault_description, exception.message)
        expected_fault.set_header(:exception, exception)
        expected_fault.set_header(:inbound_message, @msg)
        expected_fault.set_header(:context, processor)

        # act
        processor.process( @exchange )

        # assert
        @exchange.fault.should eql(expected_fault)
    end
end