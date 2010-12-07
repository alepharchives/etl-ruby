#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/io_commands'

include BehaviourSupport
include CommandSpecBehaviourSupport
include MIS::Framework

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( BulkLoadCommand ), 'when utilized to load delimited text file(s) into the staging database' do

    it 'should delegate loading to the actual bulk load component' do
        file_name = 'somefile.dump'
        db_uri = $config.connection_string
        command = BulkLoadCommand.new( file_name, 'LdapRaw' )
        columns = [
            "application_uuid",
            "owner_email",
            "application_name",
            "group_membership",
            "enabled_status_description",
            "disabled_reason"
        ]
        mock_loader = mock( 'loader' )
        SqlBulkLoader.should_receive( :new ).once.with( db_uri ).and_return( mock_loader )
        mock_loader.should_receive( :load ).once.with( :table => 'tbl_foo', :columns => columns )

        command.execute( :table => 'tbl_foo', :columns => columns )

    end

    it 'should wrap any error in the underlying driver for the caller' do
        SqlBulkLoader.stub!( :load ).and_raise( StandardError )
        lambda do
            BulkLoadCommand.new( 'filename', $config.connection_string ).execute :table => 't_foo', :columns => nil
        end.should raise_error( ProcessingError )
    end

end
