#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Service ) do
    
    it 'should explode if any of the supplied processors is nil' do
        first = lambda {
            Service.new("etl://myservice", duck, nil)
        }
        second = lambda {
            Service.new("etl://myservice", duck, dummy, nil)
        }
        [first, second].each { |run| run.should raise_error( ArgumentError, "a  processor cannot be nil" ) }
    end
    
    it "should pass on the supplied exchange to each of its processing steps" do
        exchange = dummy
        exchange.stub!(:has_fault?).and_return(false)
        steps = (1..3).to_a.collect {
            step = mock 'processor test spy'
            step.should_receive(:process).once.with(exchange)
            step.stub!(:equal).and_return(false)
            step
        }

        endpoint = Service.new("etl://myservice", duck,*steps)
        endpoint.marshal(exchange)
    end

    it 'should marshal faults to the DefaultErrorChannel unless otherwise instructed' do
        input_exchange = dummy
        input_exchange.stub!(:has_fault?).and_return(true)
        mock_err_channel = mock( 'mock_err_channel' )
        DefaultErrorChannel.stub!( :new ).and_return( mock_err_channel )
        context = dummy
        context.stub!( :default_fault_channel ).and_return( nil )
        mock_err_channel.should_receive( :marshal ).at_least( 1 ).times.with( input_exchange )

        endpoint = Service.new( "etl://myservice", context, dummy( 'exploding-processor' ) )
        endpoint.marshal( input_exchange )
    end

    it 'should marshal faults to the default fault channel specified in the given context' do                
        input_exchange = dummy
        input_exchange.stub!(:has_fault?).and_return(true)
        mock_err_channel = mock( 'mock_err_channel' )
        context = dummy
        context.stub!( :default_fault_channel ).and_return( mock_err_channel )
        mock_err_channel.should_receive( :marshal ).at_least( 1 ).times.with( input_exchange )

        endpoint = Service.new( "etl://myservice", context, dummy( 'exploding-processor' ) )
        endpoint.marshal( input_exchange )
    end
    
    it "should copy the incoming exchange and process the copy" do
        exchange = dummy('exch')
        exchange.should_receive(:copy).once.and_return(exchange)
        Service.new("etl://aservice", duck, duck).marshal(exchange)
    end
    
    it "should pass the copy to the processing nodes" do
        exchange = dummy('start-exch')
        copy = dummy('copy-exch')
        exchange.stub!(:copy).and_return(copy)
        processor1 = dummy('processor1')
        processor1.should_receive(:process).once.with(copy)
        Service.new("etl://testservice", duck, processor1).marshal(exchange)
    end
    
    it "should marshal the final result back to the original exchange" do
        exchange, copy = dummy, dummy
        exchange.stub!(:copy).and_return(copy)
        copy.should_receive(:copy_response_to).once.with(exchange)
        Service.new("etl://service2", duck, duck).marshal(exchange)
    end
    
    it 'should flip the exchange after each processing step except the last one' do
        processor_count = 10
        expected_flip_count = processor_count - 1
        processors = (1..processor_count).to_a.collect { |index| null_object( "mock-processor-#{index}" ) }

        mock_exchange = mock( 'mock-exchange' )
        mock_exchange.stub!( :has_fault? ).and_return( false )
        mock_exchange.stub!(:equal).and_return {false}
        mock_exchange.stub!(:copy_response_to)
        #TODO: is this correct!?
        mock_exchange.stub!(:inbound).and_return(dummy)
        mock_exchange.stub!(:copy).and_return(mock_exchange)
        
        mock_exchange.should_receive( :flip ).exactly( expected_flip_count ).times.and_return( mock_exchange )

        endpoint = Service.new( "etl://myservice", duck, *processors )
        endpoint.marshal( mock_exchange )
    end

    it "should copy the final processor's output to the input exchange" do
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        processor1 = Processor.new(:name=>:p1) { |ex|
            ex.outbound = Message.new
            ex.outbound.set_header(:foo, :bar)
        }
        processor2 = Processor.new(:name=>:p2) { |ex|
            ex.outbound = Message.new
            ex.outbound.set_header(:fudge, ex.inbound.headers[:foo])
        }
        endpoint = Service.new( "etl://myservice", duck, processor1, processor2 )
        endpoint.marshal(exchange)
        exchange.outbound.headers[:fudge].should eql(:bar)
    end
    
    it "should explode unless there is a valid input channel" do
        exchange = Exchange.new(dummy)
        endpoint = Service.new("etl://exploding-service", duck)
        lambda {
            endpoint.marshal(exchange)
        }.should raise_error(InvalidPayloadException)
    end
    
    #TODO: rethink this...
    it "should set a :noop message on the outbound channel if no processing takes place" do
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        endpoint = Service.new("etl://myservice", duck)
        endpoint.marshal(exchange)
        exchange.outbound.headers.should have_key(:noop)
    end

end
