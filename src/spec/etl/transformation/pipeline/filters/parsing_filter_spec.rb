#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../../../")  + '/spec_helper'

include BehaviourSupport
include MIS::Framework

describe given( ParsingFilter ), 'when filtering an input stream' do

    it 'should explode if the supplied parser is nil' do
        lambda {
            ParsingFilter.new( nil )
        }.should raise_error( ArgumentError, "the 'parser' argument cannot be nil" )
    end

    it 'should delegate to the supplied parser when filtering' do
        mock_parser = mock( 'parser' )
        input_data = "foo bar baz bugz"
        mock_parser.should_receive( :parse ).once.with( input_data ).and_return( eval( "%W(#{input_data})" ) )

        filter = ParsingFilter.new( mock_parser )
        filter.filter( input_data, get_filter_chain_stub ).should have( 4 ).items
    end

    it 'should wrap any parsing error(s) in a filter exception' do
        parser = mock( 'exploding-parser' )
        parser.should_receive( :parse ).once.and_raise( ParseError )

        lambda {
	    filter = ParsingFilter.new( parser )
	    filter.filter( "this data is ignored in this test", nil )            
        }.should raise_error( FilterException )
    end

    def get_filter_chain_stub
        mock_filter_chain = mock( 'filter-chain' )
        mock_filter_chain.should_receive( :proceed ).once { |input| input }
        return mock_filter_chain
    end

end
