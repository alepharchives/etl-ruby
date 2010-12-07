#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given(ETL::Integration::Engine::DSL::ServiceBuilder) do
    
    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = ServiceBuilder
        @constructor_args = [ 'context' ]
    end    
    
    [ :to, :from ].each do |method_name|
        it "should not respond to #{method_name}" do
            @clazz.new(dummy).should_not respond_to(method_name)
        end
    end
    
    it "should return a service as its product" do
        builder = ServiceBuilder.new(dummy)
        builder.uri = "etl://myservice2"
        builder.via(duck).product().should be_an_instance_of(Service)
    end
    
    it "should explode if we try to get a product before defining any steps" do
        lambda {
            ServiceBuilder.new(dummy).product()
        }.should raise_error(InvalidOperationException, "'steps' not set")
    end
    
end

