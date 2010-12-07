#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

######################################################################################
###############                 Behaviour Support                     ################
######################################################################################

describe "All Router behaviour", :shared => true do
    
    it 'should explode if no rule is supplied when setting a route' do
        router = new_instance
        lambda {
            router.add_route nil, dummy( 'ignored' )
        }.should raise_error( ArgumentError, "the 'rule' argument cannot be nil" )
    end

    it "should explode if an invalid 'output channel' is supplied when setting a route" do
        router = new_instance
        lambda {
            router.add_route dummy( 'rule' ), nil
        }.should raise_error( ArgumentError, "the 'output channel' argument cannot be nil" )
    end    
    
    it 'should explode if no routes are supplied prior to processing' do
        router = new_instance
        lambda {
            router.process( dummy )
        }.should raise_error( InvalidOperationException, "'routes' not set" )
    end
    
    it "should not forward data to an output channel unless an associated rule evaluates 'true'" do
        rule = mock 'rule'
        rule.stub!( :evaluate ).and_return( false )
        
        channel = mock 'channel'
        channel.should_not_receive( :marshal )
        
        router = new_instance
        router.add_route( rule, channel )
        router.process( dummy )
    end
    
    it "should forward the supplied message instance to the channel when a rule does evaluate 'true'" do
        exchange = dummy( 'exchange#1' )
        
        rule = mock 'passing-rule'
        rule.stub!( :evaluate ).and_return( true )
        
        channel = mock 'spy-channel'
        channel.should_receive( :marshal ).once.with( exchange )
        
        router = new_instance
        router.add_route( rule, channel )
        router.process( exchange )
    end
    
    it "should set a fault on the exchange if none of the supplied routes evaluate 'true'" do
        rule1, rule2 = *( [1,2].collect { |n| dummy( "rule_#{n}" ) }.each { |rule| rule.stub!( :evaluate ).and_return( false ) } )
        mock_error_channel = mock( 'error-channel' )
        dummy_exchange = dummy( 'exchange-dummy' )
        
        router = new_instance
        [ rule1, rule2 ].each { |rule| router.add_route( rule, dummy ) }
        
        dummy_exchange.should_receive( :fault= ).once { |input| input.should be_an_instance_of(Message) }
        lambda {
            router.process( dummy_exchange )
        }.should_not raise_error
    end
    
    def new_instance
	return @router_clazz.new() #( DefaultErrorChannel.new )
    end
    
end

#
#describe 'All filter behaviour', :shared => true do 
#    
#    it 'should explode if no rule is supplied' do
#        lambda {
#            @filter_clazz.new( nil, nil )
#        }.should raise_error( ArgumentError, "the 'rule' argument cannot be nil" )
#    end
#    
#    it 'should explode if no output channel is supplied' do
#        lambda {
#            @filter_clazz.new( dummy, nil )
#        }.should raise_error( ArgumentError, "the 'output channel' argument cannot be nil" )
#    end
#    
#    it "should evaluate the supplied 'rule' for each given message exchange" do
#        output_channel = dummy( 'output channel' )
#        rule = mock( 'mrule' )
#        verify_expectations( rule, output_channel ) do |expected_inputs|
#            rule.should_receive( :evaluate ).exactly( 3 ).times do |input|
#                input.should equal( expected_inputs.shift() )
#                false
#            end
#        end
#    end
#    
#    it "should marshal the supplied exchange to the output channel whenever the rule filters it in" do
#        exchanges = (1..3).to_a.collect { |n| dummy( "exchange_[#{n}]" ) }
#        rule = dummy
#        rule.stub!( :evaluate ).and_return( @filter_in_flag )
#        output_channel = mock( 'output channel' )
#
#        verify_expectations( rule, output_channel ) do |expected_inputs|
#            output_channel.should_receive( :marshal ).exactly( 3 ).times do |input|
#                input.should equal( expected_inputs.shift() )
#            end            
#        end
#    end
#    
#    it "should not marshal the supplied exchange to the output channel if the rule filters it out" do
#        rule = dummy
#        rule.stub!( :evaluate ).and_return( @filter_out_flag )
#
#        output_channel = mock( 'output channel' )
#        output_channel.should_not_receive( :marshal )
#        
#        verify_expectations( rule, output_channel )
#    end
#    
#    def verify_expectations( rule, output_channel )
#        exchanges = (1..3).to_a.collect { |n| dummy( "exchange_[#{n}]" ) }
#        yield exchanges.dup if block_given?
#        filter = @filter_clazz.new( rule, output_channel )
#        exchanges.each { |exchange| filter.process( exchange ) }
#    end    
#    
#end
