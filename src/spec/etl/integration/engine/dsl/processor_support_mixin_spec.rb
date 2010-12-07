#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::DSL::ProcessorSupportMixin) do
    
    include BuilderSupportMixin
    include ProcessorSupportMixin
    
    before :each do
        @context = duck
    end
    
    def context()
        @context
    end
    
    it "should query the service registry (i.e. context) with the target uri to perform a lookup" do
        uri = "etl://mypipeline123"
        @context.should_receive(:lookup_uri).once.with("#{uri}?api=process").and_return(duck)        
        execute(uri)
    end
        
    it 'should lookup with a valid uri in case of consume()' do
        uri = "etl://consume1"
        expected_uri = "#{uri}?api=process"
        @context.should_receive(:lookup_uri).once.with(expected_uri).and_return(duck)
        consume(uri)
    end
    
    it 'should explode if the consumer does not respond to process' do
        consumer = null_object
        @context.stub!(:lookup_uri).and_return(consumer)
        consumer.stub!(:respond_to?).and_return(false)
        
        lambda { 
            consume("etl://myconsumer")
        }.should raise_error(InvalidOperationException)
    end
    
    it "should evaluate the block supplied to 'redirect(...)' against an instance of RouteBuilder" do
        File.stub!(:directory?).and_return(true)
        expression = Expression.new { true }
        destinationuri = "lfs://usr/bin/local"
        router = redirect { where(expression).to(destinationuri) }
        router.should have(1).routes
    end

    it "should not add the route builder to the current list of builders" do
        expression, destinationuri = duck, duck
        lambda {
            redirect {
                where(expression).to(destinationuri)
            }
        }.should_not change(self, :builders)
    end

    it "should create a processor to do header setting and body copy based on the supplied inputs" do
        dummy_processor = duck
        options = { :myheader => :myvalue }
        hash = options.merge( { :body => true } )
        Processor.should_receive(:new).once.with(hash).and_return(dummy_processor)
        
        set_header( :myheader => :myvalue ).should equal(dummy_processor)
    end
    
    it "should explode if you try to create a splitter without a valid uri" do
        uri = "etl://foo/bar"
        @context.stub!(:lookup_uri).and_raise(ServiceNotFoundException.new($!, uri, @context))
        
        lambda {
            splitter(uri)
        }.should raise_error(ServiceNotFoundException)
    end
    
    it "should return a Splitter instance for a fully resolved endpoint" do
        @context.stub!(:lookup_uri).and_return(duck)
        splitter("etl://ignored/uri").should be_an_instance_of(Splitter)
    end
    
    it "should build a builder before returning a splitter, if a builder is supplied" do
        expression = duck
        @context.stub!(:lookup_uri).and_return(duck)
        builder = service("etl://myservice") { sequence(Processor.new {}) }
        builder.should_receive(:accept_visitor).once
        
        splitter(builder)
    end
    
end
