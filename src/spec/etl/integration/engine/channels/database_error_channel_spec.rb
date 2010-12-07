#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Channels::DatabaseErrorChannel) do
    
    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = DatabaseErrorChannel
        @constructor_args = [ 'database' ]
    end
    
    it "should use 'SqlCommandProcessor' with a database adapter" do
        adapter = dummy("db adapter")
        SqlCommandProcessor.should_receive(:new).with(adapter)
        @clazz.new(adapter)
    end
    
    it "should call 'SqlCommandProcessor' with the correct sql" do
        adapter = dummy("db adapter")
        exception = dummy("exception")
        
        expected_sql = "INSERT INTO errors (error_text, fault_code, fault_description) VALUES ('#{exception}', 'unhandled_exception', 'fault description')"
        
        # input exchange
        err_exchange = exchange_with_message(exception)
        
        mock_sql_command_processor.should_receive(:process).with(anything) do |arg|
            arg.inbound.body.should eql(expected_sql)
        end
        
        channel = @clazz.new(adapter)
        channel.marshal(err_exchange)
    end
    
    it "should collect all the required fields for 'ParseError'" do
        error_data = mock('error data')
        error_data.stub!(:raw_input).and_return('abc')
        error_data.stub!(:states).and_return(dummy)
        exception = ParseError.new(error_data, 'unable to parse input text')
        
        err_exchange = exchange_with_message(exception)
        
        mock_sql_command_processor.should_receive(:process).with(anything) do |arg|
            arg.inbound.body.should match(/ParseError/)
            arg.inbound.body.should match(/unable to parse input text/)
        end
        
        channel = @clazz.new(mock('adapter'))
        channel.marshal(err_exchange)
    end
    
    it "should collect all the required fields for 'DataAccessException'" do
        exception = DataAccessException.new('unable to connect to database', dummy)
        err_exchange = exchange_with_message(exception)
        
        mock_sql_command_processor.should_receive(:process).with(anything) do |arg|
            arg.inbound.body.should match(/DataAccessException/)
            arg.inbound.body.should match(/unable to connect to database/)
        end
        
        channel = @clazz.new(mock('adapter'))
        channel.marshal(err_exchange)
    end
    
    it 'should recursively collect the cause for each exception' do
        
        expA = AException.new('exception a', nil)
        expB = BException.new('exception b', expA)
        expC = CException.new('exception c', expB)
        err_exchange = exchange_with_message(expC)

        mock_sql_command_processor.should_receive(:process).with(anything) do |arg|
            arg.inbound.body.should_not be_nil
            arg.inbound.body.should match(/CException/)
            arg.inbound.body.should match(/BException/)
            arg.inbound.body.should match(/AException/) 
        end
        channel = @clazz.new(mock('adapter'))
        channel.marshal(err_exchange)
     
    end
    
    class CException < BaseException
        attr_reader :message, :inner_exception
        def initialize( message, inner_exception)
            @message = message
            @inner_exception = inner_exception
        end
            
        def body()
            return "[CException error]", "[Info CException]"
        end
    end
        
    
    class BException < BaseException
        attr_reader :message, :inner_exception
        def initialize( message, inner_exception)
            @message = message
            @inner_exception = inner_exception
        end
            
        def body()
            return "[BException error]", "[Info BException]"
        end
    end
        
    
    class AException < BaseException
        attr_reader :message, :inner_exception
        def initialize( message, inner_exception)
            @message = message
            @inner_exception = inner_exception
        end
            
        def body()
            return "[AException error]", "[Info AException]"
        end
    end
       
    
    def mock_sql_command_processor
        sql_command_processor = mock('SqlCommandProcessor')
        SqlCommandProcessor.stub!(:new).and_return(sql_command_processor)
        sql_command_processor
    end
    
    def exchange_with_message(ex)
        err_message = Message.new
        err_message.body = 'dummy'
        err_message.set_header(:context, dummy)
        err_message.set_header(:exception, ex)
        err_message.set_header(:fault_code, FaultCodes::UnhandledException)
        err_message.set_header(:fault_description, "fault description")
        err_exchange = Exchange.new(dummy)
        err_exchange.inbound = err_message
        err_exchange
    end
end

