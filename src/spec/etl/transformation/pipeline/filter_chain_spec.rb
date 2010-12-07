#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../../")  + '/spec_helper'

include BehaviourSupport
include MIS::Framework

describe "All Filter Chain behaviour", :shared => true do
    before :each do
        @chain = FilterChain.new
    end
end


describe given( FilterChain ), 'when filtering input data' do

    it_should_behave_like "All Filter Chain behaviour"

    it 'should explode unless at least one filter is supplied' do
        lambda {
            @chain.process( 'input data' )
        }.should raise_error( MissingFilterException, "no 'filters' set" )
    end

    it 'should call the filter with input data' do
        f1 = mock("Filter")
        input_data = "foo"
        f1.should_receive(:filter).with(input_data, anything)
        @chain.add_filter(f1)
        @chain.process(input_data)
    end

    it "should proceed to the next filter in the chain when instructed to do so" do
        filter1 = mock( 'f1' )
        filter2 = mock( 'f2' )
        @chain.add_filter( filter1 )
        @chain.add_filter( filter2 )
        input_data = 'foo bar baz'
        expected_second_input = input_data.upcase

        filter1.should_receive( :filter ).once do |input, filter_chain|
            filter_chain.proceed( input.upcase )
        end
        filter2.should_receive( :filter ).once.with( expected_second_input, anything )

        @chain.process( input_data )
    end

    it 'should return the result of applying all its filters' do
        filter1 = mock('cap_filter')
        filter2 = mock('reverse_filter')

        input_data = 'the quick brown fox'
        filter1.should_receive(:filter).once { |input, chain| chain.proceed input.upcase }
        filter2.should_receive(:filter).once { |input, chain| chain.proceed input.reverse }

        expected_output = 'XOF NWORB KCIUQ EHT'

        @chain.add_filter(filter1)
        @chain.add_filter(filter2)
        @chain.process(input_data).should eql(expected_output)
    end

    it 'should also allow a filter to bypass the remaining pipeline (returning early)' do
        filter = mock( 'eager-filter' )
        second_filter = mock( 'pending-filter' )
        input_data = 'rspec_tests_complete'
        filter.should_receive( :filter ).once.with( input_data, anything ).and_return( input_data.camelize )
        second_filter.stub!( :filter ).and_raise( StandardError )

        [ filter, second_filter ].each { |filter| @chain.add_filter( filter ) }

        lambda {
            @chain.process( input_data ).should eql( "RspecTestsComplete" )
        }.should_not raise_error
    end

    it "should execute it's filters in the order in which they are specified" do
        filter1 = mock( 'another-upcase-filter' )
        filter2 = mock( 'downcase-filter' )
        input_data = 'some lower case text...'
        filter1.should_receive( :filter ).once { |input, chain| chain.proceed( input.upcase.gsub( /\./, '' ) ) }
        filter2.should_receive( :filter ).once { |input, chain| chain.proceed( input.downcase ) }

        [ filter1, filter2 ].each { |filter| @chain.add_filter( filter ) }

        @chain.process( input_data ).should eql( 'some lower case text' )
    end

end

describe given( FilterChain ), 'when handling boundary conditions' do

    it_should_behave_like "All Filter Chain behaviour"

    it 'should propogate any unchecked conditions wrapped in a TransformError' do
        f1 = mock('exploding_filter')
        f1.should_receive(:filter).and_raise StandardError

        @chain.add_filter f1
        lambda do
            @chain.process 'foo'
        end.should raise_error( TransformError )
    end

    it 'should propogate any checked conditions without handling' do
        f1 = mock('exploding_filter')
        filter_error = FilterException.new( 'filter ex', nil, f1, 'foo' )
        f1.should_receive( :filter ).and_raise( filter_error )

        @chain.add_filter f1
        lambda do
            begin
                @chain.process 'foo'
            rescue FilterException => err
                err.should eql( filter_error )
                raise err
            end
        end.should raise_error( FilterException )
    end

    def verify_boundary_state( ex, expected_filter_error )
        filter_exception = ex.inner_exception
        filter_exception.should eql( expected_filter_error )
        raise ex
    end

end
