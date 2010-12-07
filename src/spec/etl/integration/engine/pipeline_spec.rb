#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

class ConsumerTestStub
    initialize_with :fault_message
    def marshal( exchange )
        exchange.fault = @fault_message
    end
    def uri()
        return self
    end
end

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Pipeline ), 'when constructing up a new pipeline' do

    it 'should explode if any of the supplied processors is nil' do
        first = lambda {
            Pipeline.new("etl://myservice", duck, nil)
        }
        second = lambda {
            Pipeline.new("etl://myservice", duck, dummy, nil)
        }
        [first, second].each { |run| run.should raise_error( ArgumentError, "a  processor cannot be nil" ) }
    end

end

describe given( ETL::Integration::Engine::Pipeline ), 'when processing a producer/consumer pair' do

    it 'should explode if the producer is nil' do
        pipeline = Pipeline.new( "etl://myservice", duck, null_object( 'dummy-filter' ) )
        lambda {
            pipeline.execute( nil, nil )
        }.should raise_error( ArgumentError, "the 'producer' argument cannot be nil" )
    end

    it 'should explode if the consumer is nil' do
        pipeline = get_pipeline_with_dummy_filter
        lambda {
            pipeline.execute( dummy( 'dummy-producer' ), nil )
        }.should raise_error( ArgumentError, "the 'consumer' argument cannot be nil" )
    end

    it 'should marshal faults to the DefaultErrorChannel unless otherwise instructed' do
        input_exchange = dummy( 'input_exchange' )
        producer = dummy( 'stub-producer' )
        exploding_processor = mock( 'exploding-processor' )
        mock_err_channel = mock( 'mock_err_channel' )

        producer.stub!( :unmarshal ).and_return( input_exchange, nil )
        exploding_processor.stub!( :process ) { |exchange| exchange.fault = dummy( 'fault' ) }
        DefaultErrorChannel.stub!( :new ).and_return( mock_err_channel )

        mock_err_channel.should_receive( :marshal ).at_least( 1 ).times.with( input_exchange )

        context = dummy
        context.stub!( :default_fault_channel ).and_return( mock_err_channel )

        pipeline = Pipeline.new( "etl://myservice", context, exploding_processor )
        pipeline.execute( producer, dummy( 'consumer' ) )
    end    

    it "should run each unmarshalled message through the whole pipeline and into the consumer" do
        exchanges = (1..3).to_a.collect { 
            exchange = dummy 
            exchange.stub!(:has_fault?).and_return(false)
            exchange
        }
        producer = dummy 'producer test stub'
        producer.stub!(:unmarshal).and_return(*(exchanges + [nil]))
        consumer = dummy 'consumer test spy'
        expected_inputs = exchanges.dup
        consumer.should_receive(:marshal).exactly(exchanges.size).times do |exchange|
            exchange.should equal(expected_inputs.shift())
            exchange
        end

        pipeline = Pipeline.new( "etl://myservice", duck, dummy )
        pipeline.execute(producer, consumer)
    end    

    it 'should check the exchange after marshalling to the consumer and direct any faults to the fault channel' do
        fault_message = dummy( 'fault message' )
        exchange = Exchange.new(dummy)
        exchange.stub!( :flip ).and_return( exchange )
        exchange.inbound = Message.new

        producer = dummy 'dogfood producer.'
        producer.stub!( :unmarshal ).and_return( exchange, nil )
        consumer = ConsumerTestStub.new( fault_message )

        fault_channel = mock 'fault_channel test spy'
        fault_channel.should_receive( :marshal ).once do |exchange|
            exchange.fault.should equal( fault_message )
        end

        pipeline = Pipeline.new( "etl://myservice", duck, dummy )
        pipeline.fault_channel = fault_channel
        pipeline.execute( producer, consumer )
    end

    it "should flip the exchage after getting it from the producer" do
        # prepare
        flipped_exchange = mock( 'flipped' )
        flipped_exchange.stub!(:inbound).and_return(Message.new)
        flipped_exchange.stub!( :has_fault? ).and_return( false )
        flipped_exchange.stub!( :copy_response_to )
        flipped_exchange.stub!(:flip).and_return(flipped_exchange)
        exchange = mock( 'exchange' )
        exchange.stub!( :flip ).and_return( flipped_exchange )
        exchange.stub!(:inbound).and_return(Message.new)

        producer = dummy 'dogfood producer.'
        producer.stub!( :unmarshal ).and_return( exchange, nil )
        pipeline = Pipeline.new( "etl://myservice", duck, duck )

        # expectations
        pipeline.should_receive( :marshal ).once.with( flipped_exchange )

        # act
        pipeline.execute( producer, dummy )      
    end

    def get_pipeline_with_dummy_filter
        Pipeline.new( "etl://myservice", duck, null_object( 'dummy-filter' ) )
    end

end
