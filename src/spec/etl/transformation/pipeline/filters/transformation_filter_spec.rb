##!/usr/bin/env ruby
#
#require 'rubygems'
#require 'spec'
#
#require File.expand_path("#{File.dirname(__FILE__)}/../../../../")  + '/spec_helper'
#
#include BehaviourSupport
#include ETL::Transforms::Pipeline::Filters
#
#describe given( TransformationFilter ), 'when filtering an input stream' do
#
#    it 'should explode if the supplied transformer is nil' do
#        lambda {
#            TransformationFilter.new( nil )
#        }.should raise_error( ArgumentError, "argument 'transformer' is required" )
#    end
#
#    it 'should delegate to the supplied transformer when filtering' do
#        transformer = mock( 'transformer' )
#        input_stack = [ :state1, :state2, :state3 ]
#        output = [ 'foo', 'bar', 'baz' ]
#        mock_filter_chain = mock( 'foo-filter-chain' )
#        transformer.should_receive( :collect ).once.with( input_stack ).and_return( output )
#        mock_filter_chain.should_receive( :proceed ).once.with( output ).and_return( output )
#
#        TransformationFilter.new( transformer ).filter( input_stack, mock_filter_chain ).should eql( output )
#    end
#
#    it 'should wrap any parsing error(s) in a filter exception' do
#        dummy_filter_chain_argument = nil
#        transformer = mock( 'exploding-transformer' )
#        transformer.should_receive( :collect ).once.and_raise( StandardError )
#
#        lambda {
#            filter = TransformationFilter.new( transformer )
#            filter.filter( "this data is ignored in this test", dummy_filter_chain_argument )
#        }.should raise_error( FilterException )
#    end
#
#end
