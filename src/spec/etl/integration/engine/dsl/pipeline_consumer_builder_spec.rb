#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine


#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::DSL::PipelineConsumerBuilder ) do

    it_should_behave_like "All tested constructor behaviour"
    it_should_behave_like "All visitable behaviour"    

    before :all do
        @clazz = PipelineConsumerBuilder
        @constructor_args = [ 'context' ]
    end    
    
    it "should not respond to 'from'" do
        PipelineConsumerBuilder.new(dummy).should_not respond_to(:from)
    end
    
    it "should explode if you try to get the product back without setting a destination uri/endpoint" do
	lambda {
	    PipelineConsumerBuilder.new(dummy).product()
        }.should raise_error(InvalidOperationException, "'consumer' not set")
    end    
    
    it "should not explode if you try to get the product back without setting up any processing steps" do
        lambda {
            builder = PipelineConsumerBuilder.new(dummy).to(dummy)
            builder.uri = "etl://someuri"
            builder.product()
        }.should_not raise_error(InvalidOperationException)
    end 
    
    it "should return a pipeline processor as its product" do
        builder = PipelineConsumerBuilder.new(dummy)
        builder.uri = "etl://myconsumer-processor"
        builder.via(duck).to(duck).product().should be_an_instance_of(PipelineConsumer)
    end 
    
    it "should register the pipeline processor ... HOW EXACTLY?" #TODO: figure this out...
    
end
