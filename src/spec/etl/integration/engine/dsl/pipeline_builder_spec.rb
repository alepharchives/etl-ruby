#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine


#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::DSL::PipelineBuilder ), 'when defining a pipeline specification' do

    include BuilderBehaviourSupport

    it_should_behave_like "All tested constructor behaviour"
    it_should_behave_like "All visitable behaviour"

    before :all do
        @clazz = PipelineBuilder
        @constructor_args = [ 'context' ]
    end
    
    [ :execute, :consume, :redirect ].each do |processor_support_method|
        it "should respond to :#{processor_support_method}" do
            @clazz.new(duck).should respond_to(processor_support_method)
        end
    end

    it "should transparently return itself, to support the DSL coding style" do
        endpoint = dummy("file://opt/bin/foo.txt")
        another_endpoint = dummy("file://opt/bin/bar.txt")
        [ endpoint, another_endpoint ].each { |ep| ep.stub!(:respond_to?).and_return(true) }
        builder = PipelineBuilder.new(dummy)
        builder.from(endpoint).to(another_endpoint).should eql(builder)
    end

    it "should call the context/registry to resolve an endpoint for a given uri" do
        File.stub!(:directory?).and_return(true)
        File.stub!(:file?).and_return(true)
        context = dummy
        builder = PipelineBuilder.new(context)
        builder.uri = "etl://builder123"
        starturi, enduri = "lfs://foo/bar", "file://mcd.csv"

        context.should_receive(:lookup_uri).once.with(starturi).and_return(duck)
        context.should_receive(:lookup_uri).once.with(enduri).and_return(duck)

        builder.from(starturi).to(enduri).product()
    end
    
    it "should not call the context/registry if the supplied object already responds to 'unmarshal'" do
        endpoint = dummy
        endpoint.stub!(:respond_to?).and_return(true)
        context = dummy
        context.should_not_receive(:resolve_endpoint_uri)
        builder = PipelineBuilder.new(context)
        builder.uri = "etl://builder/foo/bar"
        builder.from(duck).to(duck).product()
    end    

    it "should explode if you try to get the product back without setting a destination uri/endpoint" do
        lambda {
            PipelineBuilder.new(dummy).product()
        }.should raise_error(InvalidOperationException, "'producer' not set")
    end

    it "should explode if you try to get the product back without setting a source uri/endpoint" do
        File.stub!(:directory?).and_return(true)
        lambda {
            PipelineBuilder.new(dummy).from("lfs://foo/bar/baz").product()
        }.should raise_error(InvalidOperationException, "'consumer' not set")
    end

    it "should explode if the supplied processor is nil" do
        lambda {
            PipelineBuilder.new(dummy).via(nil)
        }.should raise_error(ArgumentError, "a 'processor' cannot be nil")
    end

    it "should explode unless the supplied processor responds to 'process'" do
        lambda {
            PipelineBuilder.new(dummy).via(dummy)
        }.should raise_error(ArgumentError, "Processors must respond to a 'process' message.")
    end

    it "should explode unless the uri has been set" do
        lambda {
            PipelineBuilder.new(dummy).from(duck).to(duck).via(duck).product()
        }.should raise_error(InvalidOperationException, "'uri' not set")
    end

    it "should return a pipeline processor as its product" do
        stubbed = dummy
        stubbed.stub!(:respond_to?).and_return(true)
        builder = PipelineBuilder.new(dummy)
        builder.uri = "etl://mypipeline"
        builder.from(stubbed).to(stubbed).product().should be_an_instance_of(PipelineProcessor)
    end

end
