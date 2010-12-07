#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::DSL::EndpointFilterBuilder ), 'when defining the #{method_name} endpoint of a filter specification' do

    #TODO: reconsider this in light of recent refactoring...
    #it_should_behave_like "All visitable behaviour"    

    before :all do
        @clazz = EndpointFilterBuilder
    end

    before :each do
        File.stub!(:directory?).and_return(true)
    end
    
    it "should call the context/registry to resolve an endpoint for a given uri" do
        File.stub!(:directory?).and_return(true)
        File.stub!(:file?).and_return(true)
        context = dummy
        builder = EndpointFilterBuilder.new(context)
        starturi = "lfs://foo/bar"

        context.should_receive(:lookup_uri).once.with(starturi).and_return(duck)

        builder.set_endpoint(starturi).accept(duck).product()
    end
    
    it "should not call the context/registry if the supplied object already responds to 'unmarshal'" do
        endpoint = dummy
        endpoint.stub!(:respond_to?).and_return(true)
        context = dummy
        context.should_not_receive(:resolve_endpoint_uri)
        builder = EndpointFilterBuilder.new(context)
        builder.set_endpoint(duck).accept(duck).product()
    end
    
    it "should return the uri of its endpoint once set" do
        uristring = "lfs://foo/bar/baz"
        EndpointFilterBuilder.new(dummy).set_endpoint(uristring).uri.should eql(uristring)
    end
    
    it "should return the endpoint uri, even when the supplied producer is an Endpoint instance" do
        uri = "file://c:/temp/file.txt"
        endpoint = duck
        endpoint.stub!(:uri).and_return(uri)
        
        EndpointFilterBuilder.new(dummy).set_endpoint(endpoint).uri.should eql(uri)
    end
    
    it "should explode if the supplied acceptance criteria is nil" do
        lambda {
            @clazz.new(dummy).accept(nil)
        }.should raise_error(ArgumentError, "the 'expression' argument cannot be nil")
    end

    it "should explode unless the supplied acceptance criteria responds to 'evaluate'" do
        builder = @clazz.new(dummy)
        expression = dummy
        expression.stub!(:respond_to?).and_return(false)
        lambda {
            builder.accept(expression)
        }.should raise_error(InvalidExpressionException, "The supplied expression must respond to 'evaluate'")
    end

    it "should explode if the supplied rejection criteria is nil" do
        lambda {
            @clazz.new(dummy).reject(nil)
        }.should raise_error(ArgumentError, "the 'expression' argument cannot be nil")
    end

    it "should explode unless the supplied rejection criteria responds to 'evaluate'" do
        builder = @clazz.new(dummy)
        expression = dummy
        expression.stub!(:respond_to?).and_return(false)
        lambda {
            builder.reject(expression)
        }.should raise_error(InvalidExpressionException, "The supplied expression must respond to 'evaluate'")
    end

    it "should explode if acceptance criteria is supplied in addition to rejection" do
        builder = @clazz.new(dummy)
        lambda {
            builder.reject(duck)
            builder.accept(duck)
        }.should raise_error(InvalidOperationException, "Unable to set 'accept' as criteria has already been set.")
    end

    it "should explode if acceptance criteria is supplied in addition to rejection" do
        builder = @clazz.new(dummy)
        lambda {
            builder.accept(duck)
            builder.reject(duck)
        }.should raise_error(InvalidOperationException, "Unable to set 'reject' as criteria has already been set.")
    end

    it "should explode if you try to get the product back without setting a source uri/endpoint" do
        lambda {
            @clazz.new(dummy).product
        }.should raise_error(InvalidOperationException, "'endpoint' not set")
    end

    it "should explode if you tru to get the product back without setting any criteria" do
        builder = @clazz.new(dummy)
        builder.set_endpoint("lfs://opt/cruisecontrol/projects")
        lambda {
            builder.product
        }.should raise_error(InvalidOperationException, "'expression' not set")
    end

    it "should return something that looks like a producer endpoint" do
        builder = @clazz.new(dummy)
        builder.set_endpoint("lfs://foo/bar/baz")
        builder.accept(duck)
        builder.product().should respond_to(:unmarshal)
    end

    it "should create an endpoint filter instance when building its final product" do
        dummy_ep_filter = duck
        dummy_endpoint = duck
        dummy_expression = duck
        dummy_context = duck
        EndpointFilter.should_receive(:new).once.with(dummy_endpoint, dummy_expression, dummy_context).and_return(dummy_ep_filter)

        builder = @clazz.new(dummy_context)
        builder.set_endpoint(dummy_endpoint)
        builder.accept(dummy_expression)
        builder.product().should equal(dummy_ep_filter)
    end   

end
