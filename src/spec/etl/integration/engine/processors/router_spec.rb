#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Processors::Router ), 'when initializing a new instance' do
    
    it_should_behave_like "All Router behaviour"
    
    before :all do
	@router_clazz = Router
    end
    
    it "should marshal the exchange to the first valid message channel and no others" do
	ok_rule = dummy
	ok_channel = dummy
	second_ok_rule = dummy
	second_ok_channel = mock 'suposedly ignored channel'
	[ ok_rule, second_ok_rule ].each { |rule| rule.stub!( :evaluate ).and_return( true ) }
	
	router = new_instance
	router.add_route( ok_rule, ok_channel )
	router.add_route( second_ok_rule, second_ok_channel )
	
	second_ok_channel.should_not_receive( :marshal )
	
	router.process( dummy )
    end    
    
end
