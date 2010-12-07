#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

module BuilderBehaviourSupport
    def setup_endpoint(uri_string)
        endpoint = uri_string
        context = dummy
        dummy_endpoint=dummy
        dummy_endpoint.stub!(:respond_to?).and_return(true)

        context.should_receive( :lookup_uri ).once.with(endpoint).and_return(dummy_endpoint)
        instance = @clazz.new(context) 
        instance.uri = "etl://domain_object_#{instance.object_id}"
        return instance
    end
end

describe "All visitable behaviour", :shared => true do

    mixin Validation
    
    before :each do
        validate_instance_variables(binding(), :clazz)
    end

    it "should accept a visitor and call the visit<ClassName> method" do
        builder = @clazz.new(dummy)
        visitor = mock 'visitor test spy'
        visitor.stub!(:respond_to?).and_return(true)
        visitor.should_receive("visit#{basename(@clazz.name.to_s.gsub(/::/, '/'))}".to_sym).once.with(builder)

        builder.accept_visitor(visitor)
    end
end
