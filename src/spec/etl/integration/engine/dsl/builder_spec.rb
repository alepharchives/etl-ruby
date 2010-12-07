#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

class BuilderTestClass < Builder
    def build_product()
        return nil
    end
end

class MockBuilder < Builder
    initialize_with :thing
    def build_product()
        return @thing
    end
    def accept_visitor(visitor)
        visitor.visitServiceBuilder(self)
    end
end

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::DSL::Builder) do

    before :all do
        @clazz = BuilderTestClass
    end

    before :each do
        @context = dummy
    end

    it "should stash any producer and/or consumer endpoint uris and evaluate them lazily" do
        @context.should_not_receive(:lookup_uri)
        @clazz.new(@context).from("lfs://home/test/dump").to("file://usr/local/mount/sengahro.dump")
    end

    it "should not lookup a nil producer" do
        @context.should_not_receive(:lookup_uri)
        @clazz.new(@context).to(duck).product()
    end

    it "should not lookup a nil consumer" do
        @context.should_not_receive(:lookup_uri)
        @clazz.new(@context).from(duck).product()
    end

    it "should not perform a lookup if an compatible endpoint is supplied instead of a uri" do
        endpoint = dummy
        endpoint.stub!(:respond_to?).and_return(true)
        @context.should_not_receive(:lookup_uri)
        @clazz.new(@context).from(endpoint).product()
    end

    it "should perform inline compilation if the supplied consumer is a builder instance" do
        @context.stub!(:registered?).and_return(false)
        @context.should_receive(:register_service).once
        uri = "etl://myserviceXS1N"
        mock_service = dummy("mock service...")
        mock_service.stub!(:uri).and_return(uri)
        @context.stub!(:lookup_uri).and_return(mock_service)
        builder = ServiceBuilder.new(@context).via(duck, duck)
        builder.uri = uri

        @clazz.new(@context).to(builder).from("lfs://usr/bin/local").product()
    end

    it "should perform inline compilation if the supplied producer is a builder instance" do
        @context.stub!(:registered?).and_return(false)
        @context.should_receive(:register_service).once
        uri = "etl://myserviceXS1N"
        mock_service = dummy("Another mock service...")
        mock_service.stub!(:uri).and_return(uri)
        @context.stub!(:lookup_uri).and_return(mock_service)
        builder = ServiceBuilder.new(@context).via(duck, duck)
        builder.uri = uri

        @clazz.new(@context).to("lfs://usr/bin/local").from(builder).product()
    end

    it "should lookup any producer and/or consumer uris that do not match the 'Endpoint' interface specification when creating its product" do
        builder = @clazz.new(@context).
            from(firsturi="file://mount/dataext/fallout.cmj").
            to(seconduri="file://${config.dump}/targets/${edif}.cmj")
        @context.should_receive(:lookup_uri).once.with(firsturi).and_return(duck)
        @context.should_receive(:lookup_uri).once.with(seconduri).and_return(duck)
        builder.product()
    end

    it "should attempt an api conversion if the supplied (or initially resovled) endpoint does not respond to the interface specification" do
        uri = "etl://non-responder/conversion-required"
        class NonResponder
            initialize_with :uri, :attr_reader => true
        end
        nonResponder = NonResponder.new(uri)
        builder = @clazz.new(@context).from(nonResponder)

        @context.should_receive(:lookup_uri).once.with("#{uri}?api=unmarshal").and_return(duck)
        builder.product()
    end

    it "should explode unless its subclasses override the abstract 'build_product()' method" do
        class BadBuilder < Builder
        end
        lambda {
            BadBuilder.new(@context)
        }.should raise_error(RuntimeError)
    end

    it "should return all services it depends on" do
        dependencies = ["file://mount/dataext/fallout.cmj", "file://${config.dump}/targets/${edif}.cmj"]
        builder = @clazz.new(@context).from(dependencies[0]).to(dependencies[1])

        builder.depends_on.should eql( dependencies )
    end
end
