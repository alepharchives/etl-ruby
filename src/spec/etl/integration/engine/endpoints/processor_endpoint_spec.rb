#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Framework
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Endpoints::ProcessorEndpoint ) do

    it_should_behave_like "All tested constructor behaviour"
    
    before :all do
        @clazz = ProcessorEndpoint
        @constructor_args = [ 'endpoint_uri', 'execution_context', 'processor' ]
    end
    
    it "should not respond to consumers" do
        lambda do             
            ProcessorEndpoint.new(dummy, dummy, dummy).unmarshal()
        end.should raise_error(NotImplementedException)
    end

    it "should delegate to the processor on receiving an exchange" do
        mock_processor = mock 'processor test spy!'
        exchange = dummy
        mock_processor.should_receive(:process).once.with(exchange)
        
        ProcessorEndpoint.new(dummy, dummy, mock_processor).marshal(exchange)
    end
    
end
