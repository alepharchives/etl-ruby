#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Channels::DefaultErrorChannel ), 'when initialized as new' do
    
    after :all do
        $stderr = STDERR
    end
    
    it "should use $STDERR as its output buffer" do
        channel = DefaultErrorChannel.new
        channel.send( :output_buffer ).should equal( $stderr )
    end
    
    it 'should maintain a singleton monostate, using the same output buffer for all instances' do
        first, second = DefaultErrorChannel.new, DefaultErrorChannel.new
        first.send( :output_buffer ).should equal( second.send( :output_buffer ) )
    end
    
    it 'should marshal all data to its output buffer' do
        error_message = 'dummy error message'
        $stderr.should_receive( :puts ).twice.with( error_message )
        
        mock_msg = dummy
        mock_msg.stub!( :inspect ).and_return( error_message )
        
        channel = DefaultErrorChannel.new
        channel.marshal( mock_msg )
        channel.marshal( mock_msg )
    end

end
