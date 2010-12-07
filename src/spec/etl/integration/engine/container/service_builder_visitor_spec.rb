#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

class MockEndpoint < Endpoint
    def resolve_uri(uri)
        true
    end
end

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given(ETL::Integration::Engine::Container::ServiceBuilderVisitor) do

    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = ServiceBuilderVisitor
        @constructor_args = [ 'context' ]
    end
    
    #TODO: delete these tests if the forward declaration support is really going to live in the context itself.
    
    #TODO: implement this...
    #it "should visit the producer on a filtered endpoint prior to registering the endpoint reference itself"

    
#    it "should attempt to resolve the producer and consumer on a pipeline prior to registering the pipeline itself" do
#        context = dummy
#        producer, consumer = "etl://producer", "etl://consumer"
#        context.should_receive(:lookup_uri).once.with(producer).and_return(MockEndpoint.new(producer, context))
#        context.should_receive(:lookup_uri).once.with(consumer).and_return(MockEndpoint.new(consumer, context))
#        
#        builder = PipelineBuilder.new(context).from(producer).to(consumer)
#        builder.uri = "etl://somepipelineorother"
#        visitor = ServiceBuilderVisitor.new(context)
#        builder.accept_visitor(visitor)
#    end
#
#    it "should visit the producer and consumer on a pipeline prior to registering the pipeline itself" do
#        context = duck
#        producer, consumer = dummy, dummy
#        builder = PipelineBuilder.new(context).from(producer).to(consumer)
#        builder.uri = "etl://myfirstworkingpipeline?happy=true"
#        visitor = ServiceBuilderVisitor.new(context)
#
#        [ producer, consumer ].each do |endpoint_ref|
#            endpoint_ref.should_receive(:accept_visitor).once.with(visitor)
#        end
#        builder.accept_visitor(visitor)
#    end
#    
#    it "should record the visitation once it has completed" do
#        context = duck
#        producer, consumer = dummy, dummy
#        builder = PipelineBuilder.new(context).from(producer).to(consumer)
#        builder.uri = "etl://myfirstworkingpipeline?happy=true"
#        visitor = ServiceBuilderVisitor.new(context)
#
#        builder.accept_visitor(visitor)        
#        visitor.visited?(builder.uri).should be_true
#    end

    it "should register pipeline processors with the context using the 'register_pipeline' method" do
        dummy_pipeline = dummy
        context = dummy
        context.stub!(:registered?).and_return(false)
        builder = PipelineBuilder.new(context).from(dummy).to(dummy)
        PipelineProcessor.stub!(:new).and_return(dummy_pipeline)
        visitor = ServiceBuilderVisitor.new(context)

        context.should_receive(:register_pipeline).once.with(dummy_pipeline)
        builder.uri = "etl://my-pipeline-processor"
        builder.accept_visitor(visitor)
    end
    
    it "should register endpoint filters with the context using the 'register_endpoint' method" do
        dummy_endpoint = dummy
        context = dummy
        context.stub!(:registered?).and_return(false)
        EndpointFilter.stub!(:new).and_return(dummy_endpoint)
        builder = EndpointFilterBuilder.new(context).accept(duck).set_endpoint(true_endpoint=duck)
        visitor = ServiceBuilderVisitor.new(context)

        #context.should_receive(:register_endpoint).once.with(true_endpoint)
        lambda {
            builder.accept_visitor(visitor)
        }.should raise_error(InvalidOperationException)
    end

    it "should register a consumer with the context using the 'register_consumer' method" do
        endpoint = dummy
        context = dummy
        context.stub!(:registered?).and_return(false)
        PipelineConsumer.stub!(:new).and_return(endpoint)
        builder = PipelineConsumerBuilder.new(context).to(duck).via(duck)

        visitor = ServiceBuilderVisitor.new(context)

        context.should_receive(:register_consumer).once.with(endpoint)
        builder.uri = "etl://my-consumer"
        builder.accept_visitor(visitor)
    end

    it "should register a service with the context using the 'register_service' method" do
        endpoint = dummy
        context = dummy
        context.stub!(:registered?).and_return(false)
        Service.stub!(:new).and_return(endpoint)
        builder = ServiceBuilder.new(context).via(duck)
        builder.uri = duck

        visitor = ServiceBuilderVisitor.new(context)

        context.should_receive(:register_service).once.with(endpoint)
        builder.accept_visitor(visitor)
    end

end
