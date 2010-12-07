#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Framework
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Endpoints::Splitter) do

    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = Splitter
        @constructor_args = [ 'endpoint', 'context' ]
    end

    it "should create and delegate to a producer for each exchange returned by 'unmarshal'" do
        first_message = Message.new
        second_message = Message.new
        first_exchange = Exchange.new(duck)
        first_exchange.outbound = first_message
        second_exchange = Exchange.new(duck)
        second_exchange.outbound = second_message
        first_producer = duck("p1")
        second_producer = duck("p2")
        [:first, :second].each do |producer|
            eval("#{producer}_producer").stub!(:unmarshal).and_return(eval("#{producer}_exchange"), nil)
        end
        first, second = duck("e1"), duck("e2")
        [ :first, :second ].each do |exchange|
            eval("#{exchange}").stub!(:create_producer).and_return(eval("#{exchange}_producer"), nil)
        end
        endpoint = duck
        endpoint.stub!(:unmarshal).and_return(first, second, nil)
        endpoint.stub!(:uri).and_return("etl://endpoint/foo")
        splitter = Splitter.new(endpoint, dummy)

        splitter.unmarshal().should eql(first_exchange)
        splitter.unmarshal().should eql(second_exchange)
    end
    
    it "should create a producer for an inbound exchange and repeatedly marshal from the producer to the endpoint until it returns nil" do
        exchange = duck("productive-exchange")
        inputs = (1..3).to_a.collect { 
            ex = Exchange.new(duck) 
            ex.stub!(:flip).and_return(ex)
            ex
        }
        producer = duck("test-producer")
        producer.stub!(:unmarshal).and_return(*(inputs + [nil]))
        exchange.stub!(:create_producer).and_return(producer)
        
        endpoint = duck("endpoint-test-spy")
        inputs.each { |input| endpoint.should_receive(:marshal).once.with(input) }
        
        splitter = Splitter.new(endpoint, dummy)
        splitter.marshal(exchange)
    end
    
    it "should copy the response from the last processed exchange to the input exchange's outbound channel" do
        exchange = duck("productive-exchange")
        input = Exchange.new(dummy)
        producer = duck("test-producer")
        producer.stub!(:unmarshal).and_return(input, nil)
        exchange.stub!(:create_producer).and_return(producer)

        input.should_receive(:copy_response_to).once.with(exchange)
        
        splitter = Splitter.new(dummy, dummy)
        splitter.marshal(exchange)
    end

end
