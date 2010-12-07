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

describe given( ETL::Integration::Engine::Processors::PipelineProcessor ) do

    it_should_behave_like "All tested constructor behaviour"
    
    before :all do
        @clazz = PipelineProcessor
        @constructor_args = [ 'pipeline', 'producer', 'consumer' ]
    end
    
    it "should set the producer and consumer in the headers of a processed exchange" do
        exchange = Exchange.new(dummy)
        producer, consumer = duck, duck
        processor = PipelineProcessor.new(duck, producer, consumer)
        processor.process(exchange)
        exchange.outbound.headers[:producer].should equal(producer)
        exchange.outbound.headers[:consumer].should equal(consumer)
    end
    
    it "should send the 'execute' message to its pipeline, passing the producer and consumer" do
        producer, consumer = duck, duck
        pipeline = dummy
        pipeline.should_receive(:execute).once.with(producer, consumer).and_return(duck)
        
        PipelineProcessor.new(pipeline, producer, consumer).process(duck)
    end
    
    it "should tell the resulting exchange (which is returned from Pipeline#execute) to copy its response to the original exchange" do
        pipeline = dummy
        response = dummy
        pipeline.stub!(:execute).and_return(response)
        exchange = dummy
        response.should_receive(:copy_response_to).once.with(exchange)
        
        PipelineProcessor.new(pipeline, duck, duck).process(exchange)
    end
    
    it "should take its uri from the underlying pipeline and return a path corresponding to uri + '/processor'" do
        pipeline = dummy
        pipelineuri = "etl://somepipeline"
        pipeline.stub!(:uri).and_return(pipelineuri)
        
        PipelineProcessor.new(pipeline, duck, duck).uri.should eql("#{pipelineuri}/processor")
    end
    
end
