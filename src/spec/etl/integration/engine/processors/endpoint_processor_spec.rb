#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Processors::EndpointProcessor) do

    it_should_behave_like "All tested constructor behaviour"
    
    before :all do
        @clazz = EndpointProcessor
        @constructor_args = [ 'endpoint' ]
    end
    
    it "should pass on the supplied exchange to the endpoint along with the message 'marshal'" do
        endpoint = dummy
        processor = EndpointProcessor.new(endpoint)
        exchange = dummy
        endpoint.should_receive(:marshal).once.with(exchange).and_return(duck)
        
        processor.process(exchange)
    end

end
