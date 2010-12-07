#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Channels::DatabaseAuditChannel) do
    
    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = DatabaseAuditChannel
        @constructor_args = [ 'database' ]
        @ctx = dummy
    end
    
    it "should use 'SqlCommandProcessor' with a database adapter" do
        adapter = dummy("db adapter")
        SqlCommandProcessor.should_receive(:new).with(adapter)
        @clazz.new(adapter)
    end
    
    it "should call 'SqlCommandProcessor' with the correct sql" do
        adapter = dummy("db adapter")
        msg = "msg"
        headers = {:one => "1", :two=>"2"}
        exchange = create_exchange(msg, headers)
        
        expected_sql = ["INSERT INTO workflow_audit (event_id, field_type, field_key, field_value) VALUES ('#{@ctx.object_id}', 'header', 'one', '1');",
                        "INSERT INTO workflow_audit (event_id, field_type, field_key, field_value) VALUES ('#{@ctx.object_id}', 'header', 'two', '2');",
                        "INSERT INTO workflow_audit (event_id, field_type, field_key, field_value) VALUES ('#{@ctx.object_id}', 'header', 'context', '#{@ctx}');",
                        "INSERT INTO workflow_audit (event_id, field_type, field_key, field_value) VALUES ('#{@ctx.object_id}', 'body', '#{msg.class}', '#{msg.inspect}');"]
        
        mock_sql_command_processor.should_receive(:process).with(anything) do |arg|
            expected_sql.each do |sql|
                arg.inbound.body.should include(sql)
            end
        end
        
        channel = @clazz.new(adapter)
        channel.marshal(exchange)
    end
    
    def mock_sql_command_processor
        sql_command_processor = mock('SqlCommandProcessor')
        SqlCommandProcessor.stub!(:new).and_return(sql_command_processor)
        sql_command_processor
    end
    
    def create_exchange(msg, headers_hash)
        message = Message.new
        message.body = msg
        headers_hash.each do |key, value|
            message.set_header(key, value)
        end
        message.set_header(:context, @ctx)
        exchange = Exchange.new(dummy)
        exchange.inbound = message
        exchange
    end

end