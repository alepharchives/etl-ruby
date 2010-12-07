#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::DSL::BuilderSupportMixin ) do

    include BuilderSupportMixin

    before :each do
        @context = duck
    end

    it "should return a pipeline builder instance" do
        pipeline("etl://mypipeline1").should be_an_instance_of(PipelineBuilder)
    end

    it "should set the uri on the pipeline builder prior to returning the new instance" do
        pipelineuri = "etl://pipelineuri"
        pipeline(pipelineuri).uri.should eql(pipelineuri)
    end

    it "should add the pipeline builder to the current list of builders" do
        lambda {
            pipeline("etl://mytestpipeline")
        }.should change(self, :builders)
    end

    it "should return a pipeline consumer builder instance" do
        consumer("etl://myconsumer").should be_an_instance_of(PipelineConsumerBuilder)
    end

    it "should set the uri on the pipeline consumer builder prior to returning the new instance" do
        pipelineuri = "etl://consumeruri2/foo/bar"
        consumer(pipelineuri).uri.should eql(pipelineuri)
    end

    it "should add the pipeline consumer builder to the current list of builders" do
        lambda {
            consumer("etl://dummy-consumer")
        }.should change(self, :builders)
    end

    it "should create an instance of ServiceBuidler on calls to 'service(...)'" do
        service("etl://some-service").should be_an_instance_of(ServiceBuilder)
    end

    it "should set the uri on the pipeline builder prior to returning the new instance" do
        serviceuri = "etl://serviceuri"
        service(serviceuri).uri.should eql(serviceuri)
    end

    it "should add the service builder to the current list of builders" do
        lambda {
            service("etl://mytestservice")
        }.should change(self, :builders)
    end

    it "should return the filtered endpoint directly for a 'primitive' uri scheme" do
        #TODO: test for the other three cases as well...
        filter("lfs://my/stuff") do
            accept(always())
        end.should be_an_instance_of(EndpointFilter)
    end

    it "should return the compiled and registered endpoint referenced for an 'etl' uri" do
        mock_service = duck
        @context.stub!(:registered?).and_return(false, true)
        @context.should_receive(:register_service).once
        @context.should_receive(:lookup_uri).twice.with("etl://myservicer123").and_return(mock_service)
        filter(
            service("etl://myservicer123") do
                sequence(set_header(:foo => :bar))
            end
        ) {
            accept(always())
        }.send(:instance_eval, "@endpoint").should eql(mock_service)
    end

    it "should set the default fault channel" do
        expected_fault_channel = DatabaseErrorChannel.new(dummy)
        @context = mock( 'mock_context')
        @context.should_receive( :default_fault_channel= ).at_least( 1 ).times.with(expected_fault_channel)
        default_fault_channel(expected_fault_channel)
    end

    it "should create a new instance of the supplied class for a call to default_fault_channel (set)"
    #do
    #    #TODO: URGENT: implement this
    #end

    it "should evalute the block supplied to 'service(...)' against an instance of ServiceBuilder" do
        via1, via2 = duck, duck
        lambda {
            service("etl://eval-service") do
                sequence(via1, via2)
            end
        }.should change(self, :builders)
    end

    it "should support calling 'sequece' more than once, adding new buidlers to the existing collection" do
        via1, via2, via3, via4 = *( vias = (1..4).to_a.collect { duck } )
        service = service("etl://demo2/foo/bar?query='none of your beeswax'") do
            sequence(via1, via2)
            sequence(via3, via4)
        end
        vias.each { |via| service.send(:steps).should include(via) }
    end
    
    def context
        return @context
    end

end
