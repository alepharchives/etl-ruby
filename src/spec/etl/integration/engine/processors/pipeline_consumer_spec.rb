#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

#TODO: a bit of duplication in these tests; needs refactoring....

describe given( ETL::Integration::Engine::Processors::PipelineConsumer ), 'when processing an exchange' do

    it_should_behave_like "All tested constructor behaviour" 
    
    before :all do
        @clazz = PipelineConsumer
        @constructor_args = [ 'uri', 'context', 'consumer' ]
    end
    
#    it "should explode if the consumer is nil" do
#        lambda {
#            PipelineConsumer.new( "etl://myprocessor", nil, dummy )
#        }.should raise_error( ArgumentError, "the 'consumer' argument cannot be nil" )
#    end

    it "should create and endpoint from the input exchange, to act as producer to the pipeline" do
        input_exchange = Exchange.new(dummy)
        Pipeline.stub!(:new).and_return(dummy)
        input_exchange.should_receive(:create_producer).once.and_return( mock_producer=mock("prod test spy...") )
        mock_producer.stub!(:unmarshal).and_return(exchange=dummy, nil)
        exchange.stub!(:has_fault?).and_return(false)

        processor = PipelineConsumer.new( "etl://myprocessor", duck, dummy, dummy )
        processor.process( input_exchange )
    end

    it "should process the supplied exchange, passing a producer garnered from the input exchange" do
        consumer = dummy("consumer")
        exchange = dummy("exchange...")
        exchange.stub!(:inbound).and_return(mock_message=dummy('message test spy'))
        exchange.stub!(:create_producer).and_return(producer=dummy("producer test spy"))
        mock_message.stub!(:copy_response_to)
        mock_message.stub!(:has_fault?).and_return(false)
        Pipeline.stub!(:new).and_return(pipeline=dummy('pipe'))

        processor = PipelineConsumer.new("etl://myprocessor", duck, consumer, dummy("dummy processing node"))
        pipeline.should_receive(:execute).once.with(producer, consumer).and_return(mock_message)
        processor.process(exchange)
    end

    it "should assign the output and fault channel from the last exchange, to the input exchange's output channel" do
        exchange = dummy "ignored exchange"
        output_exchange = dummy "output exchange test spy"
        Pipeline.stub!(:new).and_return(pipeline=dummy('pipeline stub'))
        pipeline.stub!(:execute).and_return(output_exchange)
        processor = PipelineConsumer.new("etl://myprocessor", duck, dummy('dummyconsumer'), dummy('dummyprocessor'))

        output_exchange.should_receive(:copy_response_to).once.with(exchange)
        processor.process(exchange)
    end

end
