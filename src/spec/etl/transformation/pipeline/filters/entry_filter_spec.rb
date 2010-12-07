#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../../../")  + '/spec_helper'

include BehaviourSupport
include MIS::Framework

describe given( EntryFilter ), 'when filtering an input stream' do

    before(:each) do
        @entry_filter = EntryFilter.new( /phrase/ )
    end

    it 'should explode if the phrase is nil' do
        lambda do
            EntryFilter.new nil
        end.should raise_error( ArgumentError, "the 'filter phrase' argument cannot be nil" )
    end

    it 'should not pass on inputs that fail to match the filter phrase' do
        mock_filter_chain = mock( 'filter-chain' )
        mock_filter_chain.should_not_receive( :proceed )

        non_matching_inputs = [ 'foo', 'bar', 'baz', nil ]
        non_matching_inputs.each do |input|
            @entry_filter.filter( input, mock_filter_chain ).should be_nil
        end
    end

    it 'should not perform any filtering if the filter phrase is empty' do
        mock_filter_chain = mock( 'mock_filter_chain' )
        mock_filter_chain.should_receive( :proceed ).exactly( 3 ).times do |input|
            input.should be_an_instance_of( String )
            #return the input just for the sake of this test!
            input
        end
        do_nothing_entry_filter = EntryFilter.new

        [
            'flobby flobby lalla',
            'wibble wobble, wibble wobble, jelly on a plate!',
            "Now, now! Let's have no more of that please sir!"
        ].each do |input|
            do_nothing_entry_filter.filter( input, mock_filter_chain ).should eql( input )
        end
    end

    it 'should explode if the filter chain is missing' do
        lambda {
            @entry_filter.filter( 'some matching phrase or other', nil )
        }.should raise_error( ArgumentError, "the 'filter chain' argument cannot be nil" )
    end

    it 'should support negating matches instead of accepting them' do
        filter, filter_chain = get_negated_filter_and_chain
        filter_chain.should_not_receive( :proceed )
        (1..10).to_a.collect { |n| "phrase_#{n}" }.each do |phrase|
            filter.filter( phrase, filter_chain )
        end

    end

    it 'should allow non-matching values through a negated filter' do
        filter, filter_chain = get_negated_filter_and_chain
        filter_chain.should_receive( :proceed ).exactly( 10 ).times.with( anything )
        (1..10).to_a.collect { |n| "flobby#{n}" }.each do |phrase|
            filter.filter( phrase, filter_chain )
        end
    end

    def get_negated_filter_and_chain
        filter = EntryFilter.new( /phrase/, :negate => true )
        filter_chain = mock( 'fc', :null_object => true )
        [ filter, filter_chain ]
    end

end
