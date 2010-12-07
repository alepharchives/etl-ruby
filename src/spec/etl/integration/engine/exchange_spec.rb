#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Exchange ), 'when first initialized' do

    it "should explode unless a context is specified" do
        lambda {
            Exchange.new(nil)
        }.should raise_error(ArgumentError)
    end

    it 'should be not failed unless the fault property is set' do
        Exchange.new(dummy).should_not have_fault
    end

    it 'should be failed once the fault property is set' do
        mex = Exchange.new(dummy)
        mex.fault = dummy
        mex.should have_fault
    end

end

describe given( ETL::Integration::Engine::Exchange ), 'when copying itself to another instance' do

    it 'should copy its outbound message to the inbound channel of the new instance' do
        first = Exchange.new(dummy)
        first.outbound = dummy( 'outbound-copy-test' )
        second = first.flip()
        second.inbound.should eql( first.outbound )
    end

    it 'should copy its fault message to the new instance' do
        mex = Exchange.new(dummy)
        mex.outbound = Message.new
        mex.fault = dummy( 'fault-copy-test' )
        flipped = mex.flip()
        flipped.should_not have_fault
        flipped.inbound.headers[:fault].should eql( mex.fault )
    end

    it "should copy its response fields (outbound and fault) to the other exchange on demand" do
        first = Exchange.new(dummy)
        first.outbound = dummy
        first.fault = dummy
        second = Exchange.new(dummy)
        first.copy_response_to(second)

        second.should eql(first)
    end

    it "should use the context to resolve a uri to create a producer" do
        mock_context = mock 'ctx'
        mex = Exchange.new(mock_context)
        mex.inbound = (message=Message.new)
        message.set_header(:scheme, 'lfs')
        message.set_header(:uri, "lfs://opt/jboss")
        producer = dummy
        producer.stub!(:respond_to?).and_return(true)
        mock_context.should_receive(:lookup_uri).once.with(message.headers[:uri]).and_return(producer)
        mex.create_producer() #.should be_an_instance_of( DirectoryEndpoint )
    end

    it "should explode if the inbound uri cannot be resolved to a producer" do
        ctx = mock 'exploding context'
        exchange = Exchange.new(ctx)
        exchange.inbound = dummy
        ctx.stub!(:lookup_uri).and_return(Object.new)

        lambda {
            exchange.create_producer()
        }.should raise_error(UnresolvableUriException)
    end

    it "should create an identical copy with the inbound and fault channels in the same place" do
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        exchange.fault = dummy

        expected_exchange = Exchange.new(dummy)
        expected_exchange.inbound = exchange.inbound
        expected_exchange.fault = exchange.fault

        exchange.copy().should eql(expected_exchange)
    end

    it "should create a reversed copy, puting the inbound to the outbound and vice versa" do
        exchange = Exchange.new(context = dummy)
        exchange.inbound = Message.new
        exchange.outbound = Message.new
        exchange.fault = dummy

        expected_exchange = Exchange.new(context)
        expected_exchange.inbound = exchange.outbound
        expected_exchange.outbound = exchange.inbound
        expected_exchange.fault = exchange.fault

        exchange.reverse().should eql(expected_exchange)
    end

end
