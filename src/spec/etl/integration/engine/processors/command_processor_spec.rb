#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine
include MIS::Framework

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Processors::CommandProcessor ) do

    it_should_behave_like "All tested constructor behaviour"
    
    before :all do
        @clazz = CommandProcessor
        @constructor_args = [ 'command' ]
    end
    
    it "should delegate to the command object on receiving a processing instruction" do
        command = mock 'command'
        command.should_receive(:execute).once
        CommandProcessor.new(command).process(dummy)
    end
    
    it "should put a status flag in the outbound headers" do
        exchange = Exchange.new(dummy)
        command = duck
        CommandProcessor.new(command).process(exchange)
        exchange.outbound.headers[:status].should eql(:complete)
    end
    
    it "should explode if the command does not support execute" do
        command = dummy
        lambda {
            CommandProcessor.new(command)
        }.should raise_error(InvalidOperationException, "A command must respond to 'execute'.")
    end
    
end
