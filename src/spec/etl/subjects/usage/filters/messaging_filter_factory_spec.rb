#!/usr/bin/env ruby

require 'rubygems'
require 'spec'
require 'date'

require File.expand_path("#{File.dirname(__FILE__)}/../../../../")  + '/spec_helper'
require File.expand_path( "#{File.dirname( __FILE__ )}/../../" ) + '/spec_helper'
require File.dirname( __FILE__ ) + '/all_filter_factories_spec'

include BehaviourSupport
include MIS::Framework

describe given(MessagingFilterFactory), 'when used to obtain a set of messaging filters' do
    
    it_should_behave_like "All filter factory behaviour"
    
    before :all do
        @@parsing_filter_instance = nil
        @grammar_file_name = 'messaging_parsing_filter.grammar'
        @parser_name = "messaging parser"
    end
    
    def get_filter_factory
        MessagingFilterFactory
    end
    
    def get_transformation_filter
        MessagingTransformationFilter
    end
    
    [ :production, :sandbox].each do | env_name |
        [ '2007-02-03', '2007-09-05'].collect { |date| Date.parse( date ) }.each do |date|
            it "should return the first entry filter for any date before and including 2007-09-05" do          
                check_entry_filter_match(/START OUTBOUND: (messaging|sms).SmsClient.sendToPlatform/, env_name, date)
            end
        end
        
        [ Date.parse('2007-09-06'), Date.parse('2008-02-03'), nil].collect { |date| date }.each do |date|
            it "should return the second entry filter for any date after 2007-09-05 or nil dates" do
                check_entry_filter_match(/continueSendMessage\(recipients/, env_name, date)
            end 
        end
    end
end