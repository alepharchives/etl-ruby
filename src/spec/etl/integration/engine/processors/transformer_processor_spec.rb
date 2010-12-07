#! /usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine
include MIS::Framework

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Processors::TransformerProcessor ) do

    it_should_behave_like "All tested constructor behaviour"
    
    before :all do
        @clazz = TransformerProcessor
        @constructor_args = [ 'transformer_file_uri' ]
    end
    
    before :each do
        @msg = Message.new
        @msg.body = "foo bar baz"
        @msg.set_header(:environment, 'sandbox')
        @exchange = Exchange.new(dummy)
        @exchange.inbound = @msg
        @mock_xformer = mock 'xformer'        
    end

    it "should call the transformer factory with the correct transformer file and environment" do
        # prepare
        uri = 'uri'
        env = 'sandbox'
        msg = Message.new
        msg.set_header(:environment, env)
        exchange = dummy( 'exchange' )
        exchange.stub!( :inbound ).and_return( msg )
        exchange.stub!( :fault= )

        # expectations
        StateTokenTransformerFactory.should_receive( :get_transformer ).with( uri, env ).and_return( dummy("xformer") )
    
        # act
        TransformerProcessor.new( uri ).process( exchange )
    end

    it "should ask the transformer to transform the message body" do
        # prepare
        StateTokenTransformerFactory.stub!( :get_transformer ).and_return( @mock_xformer )

        # expectations
        @mock_xformer.should_receive( :transform ).once.with( @msg.body )

        # act
        TransformerProcessor.new( 'xformer' ).process( @exchange )
    end
    
    it "should put the transformer output into the body of the response" do
        # prepare
        StateTokenTransformerFactory.stub!(:get_transformer).and_return( @mock_xformer )      
        xformer_output = "transformer output"
        @mock_xformer.stub!( :transform ).and_return( xformer_output )

        # act
        TransformerProcessor.new( 'xformer' ).process( @exchange )

        # assert
        @exchange.outbound.body.should eql( xformer_output )
    end

    it "should raise a fault if the transformer fails" do
        # prepare
        StateTokenTransformerFactory.stub!( :get_transformer ).and_return( @mock_xformer )        
        error_message = "Transformation failed..."
        exception = StandardError.new(error_message)      
        @mock_xformer.stub!( :transform ).and_raise exception
        
        processor = TransformerProcessor.new( 'xformer' )
        
        expected_fault = Message.new
        expected_fault.set_header(:fault_code, FaultCodes::TransformerError)
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