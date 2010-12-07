#!/usr/bin/env ruby

require 'rubygems'
require 'spec'
require 'date'
require 'faster_csv'

require File.expand_path("#{File.dirname(__FILE__)}/../../../")  + '/spec_helper'

include BehaviourSupport
include MIS::Framework

describe given( ETL::Subjects::Usage::LogfileTransformation ), 'when transforming a capability log into a data dump file' do
    
    before :each do
        @transformation = ETL::Subjects::Usage::LogfileTransformation.new
    end
    
    it "should explode if the 'environment' argument is missing" do
        lambda {
            @transformation.transform( nil, nil, nil )
        }.should raise_error( ArgumentError, "the 'environment' argument cannot be nil" )
    end
    
    it "should explode if the 'usage_type' argument is missing" do
        lambda {
            @transformation.transform( :sandbox, nil, nil )
        }.should raise_error( ArgumentError, "the 'usage type' argument cannot be nil" )        
    end
    
    it "should explode if the 'file_uri' argument is missing" do
        lambda {
            @transformation.transform( :sandbox, 'session', nil )
        }.should raise_error( ArgumentError, "the 'file uri' argument cannot be nil" )        
    end
    
    it "should explode if the 'usage type' cannot be mapped to a table name" do
        [ :foo, :bar ].each do |invalid_usage_type|
            lambda {
                @transformation.transform( :sandbox, invalid_usage_type, 'file.txt' )
            }.should raise_error( InvalidOperationException, "the supplied usage type is invalid" )
        end
    end
    
    [ :session, :capability_usage, :messaging ].each do |usage_type|
        it "should delegate to a file filter chain transformation by supplying the correct filters from a #{usage_type} filter factory" do
            log_date = '2007-10-10'
            file_uri = "#{usage_type}.log.#{log_date}"
            expected_output_file = expected_output_uri_for_usage_type( usage_type )
            File.stub!( :open ).and_yield( mock( 'ignored', :null_object => true ) )
            filter_double = mock 'filter-double', :null_object => true
            decorator_filter_double = mock 'decorator-filter-double'
            mock_factory = mock "#{usage_type}-factory"
            [ :get_parsing_filter, :get_transformation_filter, :get_entry_filters ].each do |filter_creation_method|
                mock_factory.should_receive( filter_creation_method ).once.
                    with( Date.parse( log_date ) ).
                    and_return( ( filter_creation_method.eql?( :get_entry_filters ) ) ? [ filter_double ] : filter_double )
            end        
            get_filter_factory( usage_type ).should_receive( :new ).once.and_return( mock_factory )
            DecoratorFilter.should_receive( :new ).once.with( filter_double ).and_return( decorator_filter_double )
            list_of_mock_filters = [ filter_double, decorator_filter_double, filter_double ]

            mock_filter_chain_transformation = mock 'filter-chain-transformation'
            FileFilterChainTransformation.should_receive( :new ).once.with( *list_of_mock_filters ).and_return( mock_filter_chain_transformation )
            mock_filter_chain_transformation.should_receive( :transform ).once.with( file_uri, expected_output_file )

            @transformation.transform( 'env', usage_type, file_uri )
        end

        it "should wrap the #{usage_type} parsing filter in an error handling filter, flushing caught parse errors to an output error stream" do
            log_date = '2007-05-05'
            file_uri = "#{usage_type}.log.#{log_date}"        
            invalid_token = 'sdk._2007._01.session.thirdpartycall.SessionThirdPartyCallInterface.makeCall!'
            bad_log_line = "2007-09-04 23:47:08,164 INFO [SessionThirdPartyCallInterface][][6409-63176-92425-989][urn:uuid:47535d24-2cf0-47fc-88f7-8a0dec84c052] - http-0.0.0.0-61005-2: START INBOUND: #{invalid_token}"
            expected_error_message = "received invalid token '#{invalid_token}'"
            timestamp = '10-10-10'
            environment = :sandbox
            
            pass_all_entry_filter = EntryFilter.new( /.*/ )
            exploding_parsing_filter, parsing_filter_exception = create_exploding_parsing_filter( bad_log_line, expected_error_message )

            mock_factory = mock "a #{usage_type} factory"        
            mock_factory.should_receive( :get_parsing_filter ).once.and_return( exploding_parsing_filter )
            mock_factory.should_receive( :get_transformation_filter ).once.and_return( nil )
            mock_factory.should_receive( :get_entry_filters ).once.and_return( [ pass_all_entry_filter ] )
            get_filter_factory( usage_type ).should_receive( :new ).once.and_return( mock_factory )

            mock_io = mock 'mock-io'
            expected_output_file_name = expected_output_uri_for_usage_type( usage_type )
            File.should_receive( :open ).once.with( "#{expected_output_file_name}.errors", mode='a' ).and_yield( mock_io )
            FasterCSV.stub!( :open ).and_yield( mock( 'ignored', :null_object => true ) )
            IO.should_receive( :foreach ).once.with( file_uri ).and_yield( bad_log_line )
            Time.should_receive( :now ).once.and_return( timestamp )
            Date.should_receive( :parse ).at_least( 1 ).times.and_return( 'ignored' )

            expected_error_log_info = [
                [
                    "START-ERROR-INFO: ",
                    "[timestamp: '#{timestamp}']",
                    "[environment: '#{environment}']",
                    "[details: Filter '#{parsing_filter_exception.filter}' encountered error '#{parsing_filter_exception.inspect}']",
                    "[error-message: '#{expected_error_message}']"
                ].join( '' ),
                bad_log_line,
                "END-ERROR-INFO"
            ]
            mock_io.should_receive( :puts ).exactly( 3 ).times do |input|
                expected_error_log_info.shift.should eql( input )
            end

            @transformation.transform( environment, usage_type, file_uri )        
        end        
    end
    
    def create_exploding_parsing_filter( bad_log_line, expected_error_message )
        error_data = mock 'error-data'
        error_data.should_receive( :raw_input ).and_return( bad_log_line )
        mock_states = bad_log_line.collect { |element|
            mock "mock-parser-state[for #{element}"
        }
        mock_states.last.should_receive( :message ).and_return( expected_error_message )
        error_data.should_receive( :states ).and_return( mock_states )
        
        parse_error = ParseError.new( error_data, 'unable to parse input text' )
        filter_exception = FilterException.new( expected_error_message, 
            mock( 'some-filter', :null_object => true ), bad_log_line, parse_error )
        mock_filter = mock 'exploding_filter'
        mock_filter.should_receive( :filter ).and_raise( filter_exception )
        return [ mock_filter, filter_exception ]
    end
    
    def get_filter_factory( usage_type )
        return eval( "#{usage_type.to_s.camelize}FilterFactory" )
    end
    
    def expected_output_uri_for_usage_type( usage_type )
        File.join( $config.dump_dir, "#{usage_type}_raw.dump" )
    end
    
end
