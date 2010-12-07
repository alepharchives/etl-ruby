#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

class TestEndpoint < Endpoint
    
    def initialize( uri, context )
        super
    end
    
    def resolve_uri(uri)
        return true
    end
    
end

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Endpoint ) do
    
    it_should_behave_like "All tested constructor behaviour"
    
    before :all do
        @clazz = Endpoint
        @constructor_args = [ 'endpoint_uri', 'execution_context' ]
    end
    
    it "should explode unless a uri resolver method is implemented" do
        lambda {
            endpoint = Endpoint.new("lfs://test", dummy)
        }.should raise_error(NoMethodError)
    end
    
    it "should provide a default 'unmarshal' implementation that logs" do
        lambda {
            endpoint = TestEndpoint.new(dummy, dummy)
            endpoint.should_receive(:_info).once.with(any_args())
            endpoint.unmarshal()
        }.should_not raise_error
    end

    it "should provide a default 'marshal' implementation that explodes!" do
        lambda {
            endpoint = TestEndpoint.new(dummy, dummy)
            endpoint.should_receive(:_info).once.with(any_args())
            endpoint.marshal(dummy)
        }.should_not raise_error(NotImplementedException)
    end
    
end
