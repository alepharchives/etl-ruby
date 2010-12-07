#!/usr/bin/env ruby

require 'rubygems'
require 'spec'
require 'faster_csv'

require File.expand_path("#{File.dirname(__FILE__)}/../../../")  + '/spec_helper'

include BehaviourSupport
include MIS::Framework

describe given( FileFilterChainTransformation ), 'when transforming an input file from one format to another' do
    
    it 'should wrap any filter errors in a transform error' do
        input_line = 'log line 1'
        filter = mock( 'exploding-filter' )
        filter.should_receive( :filter ).once.with( input_line, anything ).and_raise( FilterException )
        FasterCSV.should_receive( :open ).once.and_yield( mock( 'mock_writer', :null_object => true ) )
        IO.should_receive( :foreach ).once.with( anything ).and_yield( input_line )
               
        subject = FileFilterChainTransformation.new( filter )
        lambda {
            subject.transform( 'input_file_uri', 'zog' )
        }.should raise_error( TransformError )
    end
    
    it 'should explode if the supplied filter list is empty' do
        lambda {
            FileFilterChainTransformation.new
        }.should raise_error( ArgumentError, "at least one filter object is required" )
    end
    
    it 'should create a new filter chain for each transformation' do
        filters = [ mock( 'f1', :null_object => true ), mock( 'f2', :null_object => true ) ]
        filter_args = filters.dup
        mock_filter_chain = mock( 'fc', :null_object => true )
        FilterChain.should_receive( :new ).once.and_return( mock_filter_chain )
        mock_filter_chain.should_receive( :add_filter ).exactly( 3 ).times do |filter|
            filter_args.shift.object_id.should eql( filter.object_id ) unless filter_args.empty?
        end
        
        IO.stub!( :foreach ).and_return( nil )
        transform = FileFilterChainTransformation.new( *filters )
        transform.transform( 'input_file_uri', 'bar' )
    end

    it 'should wrap any io errors in a transform error' do
        mock_filter_chain = mock( 'filter-chain' )
        mock_filter_chain.should_receive( :add_filter ).once
        mock_filter_chain.should_not_receive( :process )
        FilterChain.should_receive( :new ).and_return( mock_filter_chain )

        FasterCSV.should_receive( :open ).and_raise( IOError )

        subject = FileFilterChainTransformation.new( Object.new )
        lambda {
            subject.transform( input = "foof", 'bar' )
        }.should raise_error( TransformError )
    end
    
    it 'should delegate to the csv and io apis to generate output file(s)' do
        input, output = get_test_data
        subject = FileFilterChainTransformation.new(
            setup_expectations( input, output ) do |mock_filter_chain|
                mock_filter_chain.should_receive( :process ).once.with( any_args )
            end
        )
        subject.send( :transform, input, output )
    end    
    
    def setup_expectations( input, output )
        # mock output handlers
        mock_writer = mock( 'csv-writer' )
        mock_output_filter = mock( 'output-filter' )

        # mock filters
        filter1 = mock( 'filter1' )

        FasterCSV.should_receive( :open ).once.with( output, 'a', :col_sep => '|' ).and_yield( mock_writer )
        DumpFileOutputFilter.should_receive( :new ).once.with( mock_writer ).and_return( mock_output_filter )

        mock_filter_chain = mock( 'filter-chain' )
        mock_filter_chain.should_receive( :add_filter ).twice
        yield mock_filter_chain if block_given?
        FilterChain.should_receive( :new ).and_return( mock_filter_chain )

        IO.should_receive( :foreach ).once.and_yield( 'log line 1' )

        return [ filter1 ]
    end    
    
    def get_test_data
        input, output = "input", "output"
        [ input, output ]
    end    
    
end