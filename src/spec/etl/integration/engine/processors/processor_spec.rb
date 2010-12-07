#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Processors::Processor ), 'when processing an Exchange' do

    it "should explode if the processing block was missing" do
        #TODO: this test fails when run as lambda { ... }.should raise_error(NoMethodError), but only when run in a suite!? Find out why...
        begin
            Processor.new.process(dummy)
        rescue Exception => ex
            ex.should be_an_instance_of(NoMethodError)
        end
    end

    it "should execute the defined processing block with the supplied exchange" do
        exchange = dummy
        called = false
        match = false
        processing_block = lambda { |ex| match = (ex.eql?(exchange)); called = true }
        Processor.new(&processing_block).process(exchange)
        called.should be_true
    end

    it "should evaluate the processing block in the context of the enclosing instance" do
        exchange = dummy
        processor = Processor.new do |exchange|
            @captured_exchange = exchange
        end
        processor.process(exchange)
        processor.send(:instance_variable_get, "@captured_exchange").should equal(exchange)
    end

    it "should wrap any exception generated in the processing block and set a fault on the exchange" do
        exchange = Exchange.new(dummy)
        exchange.inbound = msg=Message.new
        exception = StandardError.new("ERROR_MESSAGE")
        (processor=Processor.new { raise exception }).process(exchange)

        expected_fault = Message.new
        expected_fault.set_header(:fault_code, FaultCodes::UnhandledException)
        expected_fault.set_header(:fault_description, "ERROR_MESSAGE")
        expected_fault.set_header(:exception, exception)
        expected_fault.set_header(:inbound_message, msg)
        expected_fault.set_header(:context, processor)

        exchange.fault.should eql(expected_fault)
    end

    it "should use the supplied fault-code if it is present" do
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        processor = Processor.new(:fault_code =>(faultcode=:foo)) { raise StandardError }
        processor.process(exchange)
        exchange.fault.headers[:fault_code].should eql(faultcode)
    end

    it "should put the message (or $!) from the raised exception into the :fault_description header" do
        message = "this is the error message"
        processor = Processor.new {
            raise StandardError, message, caller
        }
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        processor.process(exchange)
        exchange.fault.headers[:fault_description].should eql(message)
    end

    it "should set the supplied event if it is present" do
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        Processor.new(:event=>(event=:new_data)) { |ex| ex.outbound = Message.new }.process(exchange)
        exchange.outbound.headers[:event].should eql(event)
    end

    it "should set the supplied command if it is present" do
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        Processor.new(:command=>(command=:foo)) { |ex| ex.outbound = Message.new }.process(exchange)
        exchange.outbound.headers[:command].should eql(command)
    end

    it "should set all the specified headers if any are present" do
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        expected_headers = {
            :foo => :bar,
            :flobby => :floo,
            :squirel => :nutkin
        }
        Processor.new(
            expected_headers
        ) { |ex| ex.outbound = Message.new }.process(exchange)

        expected_headers.each do |key, value|
            exchange.outbound.headers[key].should eql(value)
        end
    end

    it "should still set all the specified headers in the face of an exception" do
        expected_headers = {
            :header1 => 'h1',
            :header2 => 'h2',
            :header3 => 'h3'
        }
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new

        Processor.new(expected_headers) {
            raise StandardError
        }.process(exchange)

        exchange.outbound.headers.should be_semantic_eql(expected_headers)
    end

    it "should create an outbound message when setting an outbound header" do
        exchange = Exchange.new(dummy)
        expected_output = dummy

        Processor.new do |exch|
            set_outbound_header(exch, :output, expected_output)
        end.process(exchange)

        exchange.outbound.headers.should be_semantic_eql( :output => expected_output )
    end

    it "should eval any set-header options that quack like an expression" do
        exchange = Exchange.new(dummy)
        inbound = Message.new
        inbound.set_header(:basename, basename='sandbox')
        exchange.inbound = inbound

        Processor.new(:environment=>HeaderExpression.new(:basename)) { |ex|
            ex.outbound = Message.new
        }.process(exchange) #just :env=>basename in the DSL though!

        exchange.outbound.headers[:environment].should eql(basename)
    end

    it "should eval any header that is contained within a special tag ${like_this} and get back an instance variable based on the name" +
        " putting it into the outbound headers" do
        exchange = Exchange.new(dummy)
        message = Message.new
        message.set_header(:basename, (env='sandbox'))
        exchange.inbound = message
        Processor.new(:environment=>'${environment}') do |ex|
            @environment = ex.inbound.headers[:basename]
            ex.outbound = Message.new
        end.process(exchange)

        exchange.outbound.headers[:environment].should eql(env)
    end

    it "should clear any 'internal expression langauge' targetted instance variables prior to each processing run, by setting them to nil" do
        class ProcessorTestSpy < Processor
            attr_reader :environment
        end
        external_system = lambda { :foo }
        processor = ProcessorTestSpy.new(:environment=>'${environment}') do |ex|
            @environment = external_system.call()
        end
        processor.process(dummy)
        processor.environment.should eql(:foo)

        external_system = lambda { raise StandardError }

        lambda {
            processor.process(dummy)
        }.should change(processor, :environment).to(nil)
    end

    it "should transparently provide access to the inbound headers of the supplied exchange" do
        exchange = Exchange.new(dummy)
        message = Message.new
        [ :foo, :bar ].each { |name| message.set_header(name, name.to_s.succ.to_sym) }
        exchange.inbound = message

        Processor.new(:foo=>'${foo}', :bar=>'${bar}') do |ex|
            @foo, @bar = inheader(:foo), inheader(:bar)
            ex.outbound = Message.new
        end.process(exchange)

        expected_headers = {
            :foo => :fop,
            :bar => :bas
        }
        expected_response = Message.new
        expected_headers.each { |k,v| expected_response.set_header(k,v) }

        exchange.outbound.should eql(expected_response)
    end

    it "should transparently provide access to the body of the supplied exchange" do
        exchange = Exchange.new(dummy)
        message = Message.new
        body = "foo bar baz"
        message.body = body
        exchange.inbound = message

        Processor.new do |exchange|
            set_outbound_header(exchange, :body, body(exchange))
        end.process(exchange)

        exchange.outbound.headers[:body].should eql(body)
    end

    it "should automatically create an outbound exchange, if none is generated during execution of the processing block" do
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        Processor.new { }.process(exchange)
        exchange.outbound.should_not be_nil
    end

    it "should copy over the original headers from the inbound message" do
        expected_headers = {
            :foo => 'bar',
            :flobby => 'floo'
        }
        exchange = Exchange.new(dummy)
        input = Message.new
        expected_headers.each do |key, value|
            input.set_header(key, value)
        end
        exchange.inbound = input

        Processor.new { |exch| exch.outbound = Message.new }.process(exchange)
        expected_headers.should be_semantic_eql(exchange.outbound.headers)
    end

    it "should copy over the original body to the new message when requested via the constructor" do
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        body = "foo bar baz"
        exchange.inbound.body = body
        
        expected_outbound_message = Message.new
        expected_outbound_message.body = body

        Processor.new( :body => true ) {}.process(exchange)

        exchange.outbound.should eql(expected_outbound_message)
    end

    it "should not copy original headers over new ones!" do
        exchange = Exchange.new(dummy)
        input = Message.new
        input.set_header(:cor, 'blimey')
        exchange.inbound = input
        expected_header_value='that is a very nice feature!'

        Processor.new do |exch|
            exch.outbound = Message.new
            exch.outbound.set_header(:cor, expected_header_value)
        end.process(exchange)

        exchange.outbound.headers[:cor].should eql(expected_header_value='that is a very nice feature!')
    end

end
