#!/usr/bin/env ruby

require 'rubygems'
require 'spec'
require 'postgres'

require File.dirname(__FILE__) + '/../../../spec_helper'

include BehaviourSupport
include MIS::Framework

describe given( ETL::Integration::SQL::ErrorHandlerMixin ), 'when used to launder postgresql driver generated exceptions' do
    
    include ErrorHandlerMixin
    
    it 'should wrap connection startup errors in a connectivity exception' do
        connect_error_message = 'connect(2)'
        connect_error = Errno::EBADF.new( connect_error_message )
        error_code = :UNKNOWN
        expected_message = "FATAL ERROR: unable to establish connection. #{connect_error.message}"
        expected_severity = :FATAL
        
        mock_driver = mock( 'driver' )
        mock_driver.should_receive( :connection_string ).once.and_return( expected_data_source_uri='foo' )
        expected_exception_object = ConnectivityException.new( expected_data_source_uri, expected_message, 
            connect_error, expected_severity, error_code )
        
        apply_expectations( method( :on_connect_error ), connect_error, 
            ConnectivityException, expected_exception_object, mock_driver )
    end
    
    it 'should provide special handling invalid catalog name error code to a connectivity exception' do
        invalid_catalog_error_message = 'database "invalid_catalog" does not exist'
        connect_error_message = "FATAL     C3D000  M#{invalid_catalog_error_message}      Fpostinit.c     L318    RInitPostgres"
        connect_error = RuntimeError.new( connect_error_message )
        error_code = :C3D000
        expected_message = "#{error_code}: unable to establish connection. #{invalid_catalog_error_message}"
        expected_severity = :FATAL
        
        mock_driver = mock( 'driver' )
        mock_driver.should_receive( :connection_string ).once.and_return( expected_data_source_uri='foo' )
        
        expected_exception_object = ConnectivityException.new( expected_data_source_uri, expected_message, 
            connect_error, expected_severity, error_code )
        
        apply_expectations( method( :on_connect_error ), connect_error, 
            ConnectivityException, expected_exception_object, mock_driver )
    end
    
    it 'should wrap data access error in an appropriate layer exception' do
        error_severity = :ERROR
        error_code = :C42P01
        system_message = "relation \"foo\" does not exist"
        error_message = "#{error_severity}     #{error_code}  M#{system_message}  Fnamespace.c    L221    RRangeVarGetRelid"
        error = RuntimeError.new( error_message )
        
        expected_message = "#{error_code}: #{system_message}"
        expected_exception_object = DataAccessException.new( expected_message, error, error_severity, error_code )
        
        apply_expectations( method( :on_data_access_error ), error, DataAccessException, expected_exception_object )
    end
    
    it 'should provide special handling for system call errors wrapped in data access exceptions' do
        severity, error_code = :FATAL, :UNKNOWN
        [
            Errno::EPIPE.new( 'Broken pipe' ),
            Errno::ECONNREFUSED.new( 'Connection refused - connect(2)' ),
            Errno::ECONNRESET.new( 'An existing connection was forcibly closed by the remote host.' )
        ].each do |system_error|
            expected_message = "#{error_code} (#{severity}): #{system_error.class}: #{system_error.message}"
            expected_exception_object = DataAccessException.new( expected_message, system_error, severity, error_code )
            
            apply_expectations( method( :on_data_access_error ), system_error, DataAccessException, expected_exception_object )
        end        
    end
    
    def apply_expectations( method, exception_object, exception_clazz, expected_object, driver=nil )
        lambda {
            begin
                if driver.nil?
                    method.call( exception_object )
                else
                    method.call( exception_object, driver )
                end                
            rescue exception_clazz => ex
                #puts ex.to_s
                #puts expected_exception_object.to_s
                ex.should eql( expected_object )
                raise ex
            end
        }.should raise_error( exception_clazz, expected_object.message )            
    end
    
end
