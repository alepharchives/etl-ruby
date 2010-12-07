#!/usr/bin/env ruby

require 'rubygems'
require 'spec'
require 'date'

require File.expand_path("#{File.dirname(__FILE__)}/../../../../")  + '/spec_helper'
require File.expand_path( "#{File.dirname( __FILE__ )}/../../" ) + '/spec_helper'
require File.dirname( __FILE__ ) + '/all_filter_factories_spec'

include BehaviourSupport
include MIS::Framework

describe given( CapabilityUsageFilterFactory ), 'when used to obtain a set of session filters' do
    
    it_should_behave_like "All filter factory behaviour"
    
    before :all do
        @@parsing_filter_instance = nil
        @grammar_file_name = 'usage_parsing_filter.grammar'
        @parser_name = "capability usage parser"
    end
    
    def get_filter_factory
        CapabilityUsageFilterFactory
    end
    
    def get_transformation_filter
        UsageTransformationFilter
    end
    
    [ :production, :sandbox ].each do |env_name|
        [ '2007-02-03', '2007-09-05', '2007-11-10' ].collect { |date| Date.parse( date ) }.each do |date|
            it "should return a pair of entry filters for any given date (upto, including and beyond #{date}) in environment #{env_name}" do
                entry_filter_criteria = [ /END INBOUND/, /ContactsAvailabilityInterface/ ]
                entry_filter = mock( "entry-filter-[#{entry_filter_criteria[0]}]" )
                deprecated_service_filter = mock( "deprecated-service-filter-[#{entry_filter_criteria[1]}]" )
                filters = [ entry_filter, deprecated_service_filter ]
                filter_lookup_results = filters.dup
                criterion = entry_filter_criteria.dup

                EntryFilter.should_receive( :new ).twice do |criteria, options|
                    options[ :negate ].should be_true unless options.nil? || options.empty?  
                    criteria.should eql( criterion.shift )
                    filter_lookup_results.shift
                end

                factory = CapabilityUsageFilterFactory.new( env_name )
                results = factory.get_entry_filters( date )
                results.each { |filter| filter.should eql( filters.shift ) }
#              check_entry_filter_match(/END INBOUND/, env_name, date)
#              check_entry_filter_match(/ContactsAvailabilityInterface/, env_name, date)
            end          
        end    
    end
end
