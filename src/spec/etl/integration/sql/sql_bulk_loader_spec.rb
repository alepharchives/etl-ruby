#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../../")  + '/spec_helper'

include BehaviourSupport
include MIS::Framework

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe 'all database connectivity providers', :shared => true do
    before :all do
        #note: DataAdapter's connection factory-esque behaviour requires
        #    you to extend the module yourself. See the rdoc comments for details.

        module ETL::Integration::DataAdapter
            @@supported_drivers = {
                :postgres => {
                    :class_name => 'Object',
                    :method_name => 'connect'
                }
            }
        end
    end

    before :each do
        @mock_connection = mock( 'connection' )
    end
end

describe given( SqlBulkLoader ), 'when supplied with a connection string' do

    include SqlBehaviourSupport

    it_should_behave_like 'all database connectivity providers'

    it 'should not explode if the uri is valid' do
        bulk_loader_with_valid_connectivity.send( :connect )
    end

    it 'should explode if the uri is invalid' do
        loader = SqlBulkLoader.new( 'http://www.google.com' )
        lambda do
            dummy_load loader
        end.should raise_error( ConnectivityException )
    end

    it 'should explode when given a valid connection string but the database is unavailable' do
        setup_postgres_connectivity_expectations_on(
            "localhost", 10501, "NON_EXISTENT_DATABASE", "dummy_user", "password") do |wrap|
            wrap.and_raise( Exception )
        end

        #Object.should_receive( :connect ).with( :any_args ).and_raise( Exception )

        dodgy_connection_string = 'postgres://localhost:10501/NON_EXISTENT_DATABASE?user=dummy_user&password=password'
        loader = SqlBulkLoader.new dodgy_connection_string
        lambda do
            dummy_load loader
        end.should raise_error( ConnectivityException )
    end

    def dummy_load( loader )
        loader.load(
            :file_uri => 'any.csv',
            :delimiter => ',',
            :mapping_rules => { :irrelevant => :any }
        )
    end
end

describe given( SqlBulkLoader ), 'when asked to load data from a file' do

    include SqlBehaviourSupport

    it_should_behave_like 'all database connectivity providers'

    it 'should wrap all errors originating with the underlying driver' do
        loader = bulk_loader_with_valid_connectivity
        loader.should_receive( :copy_statement_for ).and_return( 'an imaginary sql statement...' )
        @mock_connection.should_receive( :execute_command ).once.and_raise( Exception )
        @mock_connection.should_receive( :close ).once
        lambda do
            loader.load( {:dummy_options => :ignored} )
        end.should raise_error( DataAccessException )
    end

    [ :file_uri, :delimiter, :mapping_rules ].each do |required_argument|
        it "should validate the presence of the #{required_argument} argument before loading" do
            table, file, delimiter, mapping_rules = default_mapping_properties_for nil
            loader_options = eval <<-EOF
            {
                    #{':file_uri => file,' unless required_argument == :file_uri}
                    #{':delimiter => delimiter,' unless required_argument == :delimiter}
                    #{':mapping_rules => mapping_rules,' unless required_argument == :mapping_rules}
            }
            EOF

            #puts "calling #load without option #{required_argument}, using #{loader_options.inspect}"
            @mock_connection.should_not_receive( :execute_command )
            @mock_connection.should_receive( :close ).any_number_of_times
            lambda do
                bulk_loader_with_valid_connectivity.load loader_options
            end.should raise_error( ArgumentError )
        end
    end

    [ :table, :columns ].each do |require_mapping_rule|
        #:table,
        it "should validate the presence of the #{require_mapping_rule} mapping rule during a call to SqlBulkLoader#load" do
            bad_rules = eval <<-EOF
                {
                    #{':table => :some_table,' unless require_mapping_rule.to_sym == :table}
                    #{':columns => [ :col1, :col2, :col3, :col4 ],' unless require_mapping_rule.to_sym == :columns}
                }
            EOF
            @mock_connection.should_receive( :close ).any_number_of_times
            lambda do
                bulk_loader_with_valid_connectivity.load(
                    :file_uri => 'a_file.csv',
                    :delimiter => ',',
                    :mapping_rules => bad_rules
                )
            end.should raise_error( ArgumentError )
        end
    end

    it 'should ignore schema if not specified' do
        no_schema = nil
        with_expecations_for_loading no_schema do |file, delimiter, mapping_rules|
            bulk_loader_with_valid_connectivity.load(
                :file_uri => file,
                :delimiter => delimiter,
                :mapping_rules => mapping_rules
            )
        end
    end

    it 'should pass on the correct mappings to the database' do
        schema = 'public'
        with_expecations_for_loading schema do |file, delimiter, mapping_rules|
            bulk_loader_with_valid_connectivity.load(
                :file_uri => file,
                :delimiter => delimiter,
                :mapping_rules => mapping_rules
            )
        end
    end

    def default_mapping_properties_for( schema )
        table = 'LDAP_Raw'
        file = 'file.csv'
        delimiter = '|'
        mapping_rules = {
            :table => table,
            :columns => [
                "application_uuid",
                "owner_email",
                "application_name",
                "group_membership",
                "enabled_status_description",
                "disabled_reason"
            ]
        }
        mapping_rules.store( :schema, schema ) unless schema.nil?
        [table, file, delimiter, mapping_rules]
    end

    def with_expecations_for_loading( optional_schema_mapping=nil )
        table, file, delimiter, mapping_rules = default_mapping_properties_for optional_schema_mapping

        expected_sql_statement=<<-EOF
            COPY #{optional_schema_mapping.nil? ? '' : "\"#{optional_schema_mapping}\"."}"#{table}" (
                #{mapping_rules[:columns].join( ',' )}
            )
            FROM '#{file}'
            WITH DELIMITER AS '#{delimiter}'
            NULL AS 'NULL';
        EOF

        @mock_connection.should_receive( :execute_command ).with( expected_sql_statement.trim_lines ).once
        @mock_connection.should_receive( :close ).once
        yield file, delimiter, mapping_rules if block_given?
    end

end
