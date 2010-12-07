#!/usr/bin/env ruby

require 'rubygems'
require 'spec'
require 'date'

require File.expand_path("#{File.dirname(__FILE__)}/../../../../")  + '/spec_helper'
require File.expand_path( "#{File.dirname( __FILE__ )}/../../" ) + '/spec_helper'
require File.dirname( __FILE__ ) + '/all_filter_factories_spec'

include BehaviourSupport
include MIS::Framework

describe given(CallflowElementFilterFactory), 'when used to obtain a set of callflow element filters' do
    
    it_should_behave_like "All filter factory behaviour"
    
    before :all do
        @@parsing_filter_instance = nil
        @grammar_file_name = 'callflow_element_parsing_filter.grammar'
        @parser_name = "callflow element usage parser"
    end
    
    def get_filter_factory
        CallflowElementFilterFactory
    end
    
    def get_transformation_filter
        CallflowElementTransformationFilter
    end
      
    [ :production, :sandbox].each do | env_name |
        [ Date.parse('2008-02-03'), Date.parse('2007-12-05'), nil].collect { |date| date }.each do |date|
            it "should return the entry filter for any date, including nil" do
                check_entry_filter_match(/CALLFLOW ELEMENT MIS DATA/, env_name, date)
            end
        end         
    end
end