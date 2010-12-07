#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include CommandSpecBehaviourSupport
include MIS::Framework

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( DatabaseTransformCommand ), 'when used to cleanse and conform data within staging' do

    it 'should call the stored procedure defined in the mapping arguments' do
        command = DatabaseTransformCommand.new 'sourcetable', 'destinationtable'
        mock_database = mock( 'database' )
        Database.stub!( :connect ).and_return( mock_database )
        expected_statement = 'select fn_example();'
        mock_database.should_receive( :exec ).once.with( expected_statement )
        command.execute( expected_statement )
    end

    it 'should wrap any errors in the underlying driver' do
        command = DatabaseTransformCommand.new 'sourcetable', 'destinationtable'
        mock_database = mock( 'database' )
        Database.stub!( :connect ).and_return( mock_database )
        expected_statement = 'select fn_example();'
        mock_database.should_receive( :exec ).once.with( expected_statement ).and_raise( StandardError )
        lambda do
            command.execute( expected_statement )
        end.should raise_error( ProcessingError )
    end

end
