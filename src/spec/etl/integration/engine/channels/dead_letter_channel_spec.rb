#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Channels::DeadLetterChannel) do

    it "should log all exchanges that come in to it" do
        channel = DeadLetterChannel.new()
        exchange = Exchange.new(dummy)
        exchange.inbound = msg=Message.new
        uri = dummy
        uri.full_path = "foo"
        msg.set_header(:uri, uri)
        Kernel.should_receive(:_info).once.with(/Received exchange from \[.*\]\./i, nil, channel)
        channel.marshal(exchange)
    end

end
