#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given(ETL::Integration::Engine::Container::ServiceConfigurationBuilder) do

    it "should explode unless a subclass responds to the 'configure' message" do
        class BadServiceBuilder < ServiceConfigurationBuilder
        end
        lambda {
            BadServiceBuilder.new.build(duck)
        }.should raise_error(NotImplementedException)
    end

    it "should send itself the 'configure' message prior to registering any services" do
        #TODO: Just answer me one question - why doesn't this blow up when the previous test does!? 8-{
        class TestConfiguredServiceBuilder < ServiceConfigurationBuilder
        end
        builder = TestConfiguredServiceBuilder.new
        builder.should_receive(:configure).once
        builder.build(duck)
    end

    it "should forward the 'include' message to the receiver's class" do
        class TargetBuilderClass < ServiceConfigurationBuilder
            def configure()
                include Validation
            end
        end
        TargetBuilderClass.should_receive(:include).once.with(Validation)
        builder = TargetBuilderClass.new
        builder.build(duck)
    end

    it "should transparently consume the state of the builder support mixins" do
        class ProductiveBuidlerClass < ServiceConfigurationBuilder
            def configure()
                require "rubygems"

                include MIS::Workflow

                #my workflow example...
                pipeline("etl://mypipeline").
                    from("lfs:/sourcedir").
                    to("lfs:/targetdir").
                    via(
                        Processor.new {}
                    );
            end
        end
        builder = ProductiveBuidlerClass.new
        lambda {
            builder.build(duck)
        }.should change(builder, :builders)
    end

    it "should visit each builder in the builders collection created by 'configure'" do
        visitorImpl = dummy
        ServiceBuilderVisitor.stub!(:new).and_return(visitorImpl)
        builders = (1..3).to_a.collect { duck }
        $builders_id = builders.object_id
        class MockConfigurationBuilder < ServiceConfigurationBuilder
            include ObjectSpace
            def configure()
                @builders = _id2ref($builders_id)
            end
        end
        builders.each do |builder|
            builder.should_receive(:accept_visitor).once.with(visitorImpl)
        end

        subject = MockConfigurationBuilder.new
        context = duck
        context.stub!(:registered?).and_return(false)
        subject.build(context)
    end

end
