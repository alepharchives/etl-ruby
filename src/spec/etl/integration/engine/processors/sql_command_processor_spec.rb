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

describe given( ETL::Integration::Engine::Processors::SqlCommandProcessor ) do

    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = SqlCommandProcessor
        @constructor_args = [ 'database' ]
    end

    it "should execute the SQL in the body of a command message" do
        command = Message.new
        command.body = "create table foo(id integer, name varchar(255));"
        command.set_header(:command, :SQL)
        command.set_header(:command_type, :DDL)
        exchange = Exchange.new(dummy)
        exchange.inbound = command
        adapter = dummy("db adapter ...")
        dummy_command = dummy("db command...")
        adapter.should_receive(:create_command).once.with(command.body).and_return(dummy_command)
        dummy_command.should_receive(:execute)
        
        processor = @clazz.new(adapter)
        processor.process(exchange)
    end

    it "should explode if the inbound message has no body" do
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        lambda {
            @clazz.new(dummy).send(:do_process,exchange)
        }.should raise_error(InvalidPayloadException)
    end

    it "should set the :fault_code header to :invalid_payload if the inbound message has no body" do
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        @clazz.new(dummy).process(exchange)
        exchange.fault.headers[:fault_code].should eql(FaultCodes::InvalidPayload)
    end

    it "should set the :fault_code header to :sql_error in the face of a data access exception" do
        exploding_adapter = dummy
        exploding_adapter.stub!(:connect).and_raise(ConnectivityException)
        exchange = Exchange.new(dummy)
        exchange.inbound = dummy
        processor = @clazz.new(exploding_adapter)
        processor.send(:instance_eval) do
            @options[:fault_code] = nil
        end
        processor.process(exchange)
        exchange.fault.headers[:fault_code].should eql(FaultCodes::SqlError)
    end

    it "should open the adapter prior to executing the supplied command text" do
        adapter = dummy('db adapter . . . ')
        processor = @clazz.new(adapter)
        adapter.should_receive(:connect).once

        processor.process(dummy)
    end

    it "should close the adapter after processing, even in the face of a raised exception" do
        adapter = mock("exploding adapter. . .")
        processor = @clazz.new(adapter)
        adapter.should_receive(:connect).once.ordered
        adapter.stub!(:execute).and_raise(StandardError)
        adapter.should_receive(:connected?).once.ordered.and_return(true)
        adapter.should_receive(:disconnect).once.ordered
        processor.process(dummy)
    end

    it "should put the result set in the :response header" do
        adapter = dummy
        dummy_command = dummy
        dummy_resultset = dummy
        command_processor = @clazz.new(adapter)
        
        adapter.stub!(:create_command).and_return(dummy_command)
        command_processor.stub!(:get_command_response).and_return(dummy_resultset)
        exchange = Exchange.new(dummy)
        exchange.inbound = dummy

        command_processor.process(exchange)

        exchange.outbound.headers[:response].should equal(dummy_resultset)
    end

    it "should pass the parameters to the command when executing the query" do
        adapter = dummy
        dummy_command = dummy
        params = [1,2,3]
        adapter.stub!(:create_command).and_return(dummy_command)
        dummy_command.should_receive(:execute).with(1,2,3)
        
        exchange = Exchange.new(dummy)
        command = Message.new          
        command.set_header(:command, :SQL)
        command.set_header(:command_type, :DDL)
        command.set_header(:params, params)
        command.body = duck
        exchange.inbound = command
        
        @clazz.new(adapter).process(exchange)
    end
    
end
