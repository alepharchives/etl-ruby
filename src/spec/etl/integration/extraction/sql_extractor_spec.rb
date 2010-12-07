#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../../")  + '/spec_helper'
include BehaviourSupport
include MIS::Framework

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe 'all database extract connectivity providers', :shared => true do
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
        @mock_command = mock 'command'
    end
end

describe given( ETL::Integration::Extraction::SqlExtractor ), 'when supplied with a connection string' do

    include SqlBehaviourSupport

    it_should_behave_like 'all database extract connectivity providers'

    it 'should not explode if the uri is valid' do
      data_extractor_with_valid_connectivity.send(:connect)
    end

    it 'should explode if the uri is invalid' do
        bad_uri = 'http://www.google.com'
        lambda do
            extractor = ETL::Integration::Extraction::SqlExtractor.new bad_uri
            dummy_extract( extractor )
        end.should raise_error( ConnectivityException )
    end


    it 'should explode when given a valid connection string but the database is unavailable' do
        setup_postgres_connectivity_expectations_on(
        "localhost", 10501, "NON_EXISTENT_DATABASE", "dummy_user", "password") do |wrap|
            wrap.and_raise( Exception )
        end

        #Object.should_receive( :connect ).with( :any_args ).and_raise( Exception )

        dodgy_connection_string = 'postgres://localhost:10501/NON_EXISTENT_DATABASE?user=dummy_user&password=password'
        extractor = ETL::Integration::Extraction::SqlExtractor.new dodgy_connection_string
        lambda do
            dummy_extract( extractor )
        end.should raise_error( ConnectivityException )
    end

    def dummy_extract( sqlAdapter )
        sqlAdapter.extract(
            :environment => 'development',
            :schema => 'public',
	    :source_table => 'bucket',
            :delimiter => ',',
            :criteria => {},
            :mapping_rules => {}
        )
    end
end


describe given( ETL::Integration::Extraction::SqlExtractor ), 'When environment option is passed' do

    include SqlBehaviourSupport

    it_should_behave_like 'all database extract connectivity providers'

    it 'should pass on the environment column in the sql' do
        expected_sql_statement = %(select *, 'development' as environment from "public"."table_name";)

        ext_options = {
            :environment => 'development',
            :schema => 'public',
            :source_table => 'table_name'
        }

        @mock_connection.should_receive( :create_command ).with( expected_sql_statement ).once.and_return( @mock_command )
        @mock_command.should_receive( :execute )
        @mock_connection.should_receive( :close ).once

        data_extractor_with_valid_connectivity.extract(ext_options)
    end
end

describe given( ETL::Integration::Extraction::SqlExtractor ), 'when asked to extract data from the database' do

    include SqlBehaviourSupport

    it_should_behave_like 'all database extract connectivity providers'

    [ :schema, :source_table ].each do |required_argument|
        it "should validate the presence of the #{required_argument} argument before extracting" do
            environment, schema, source_table, criteria = default_mapping_properties
            ext_options = eval <<-EOF
                  {
                          #{':schema => schema,' unless required_argument == :schema}
                          #{':source_table => source_table' unless required_argument == :source_table}
                  }
                  EOF

            @mock_connection.should_not_receive( :create_command )
            @mock_connection.should_receive( :close ).any_number_of_times
	    extractor = SqlExtractor.new "postgres://localhost:1658/CAT_STAGING?user=login1&password=n007hfyr8847"
            lambda do
                extractor.extract ext_options
            end.should raise_error( ArgumentError )
        end
    end

    it 'should pass on the correct sql with multiple criteria to the database' do
        expected_sql_statement = %(select *, 'development' as environment from "public"."some_table" where when_created = '2007-08-05' and second_column = 'AbC';)

        environment, schema, source_table, criteria =
            mapping_properties("development", "public", "some_table", %(when_created = '2007-08-05' and second_column = 'AbC'))

        ext_options = {
            :environment => 'development',
            :schema => schema,
            :source_table => source_table,
            :criteria => criteria
        }

        @mock_connection.should_receive( :create_command ).with( expected_sql_statement ).once.and_return( @mock_command )
        @mock_command.should_receive( :execute )
        @mock_connection.should_receive( :close ).once

        data_extractor_with_valid_connectivity.extract(ext_options)
    end

    it "should pass on the correct sql with joins to the database" do
        #setup
        schema = "public"
        source_table = "some_table"
        join = "inner join other_table on (some_id = other_id)"
        ext_options = {
            :environment => 'development',
            :schema => schema,
            :source_table => source_table,
            :join => join
        }

        # expectations
        expected_sql_statement = "select *, 'development' as environment from \"public\".\"some_table\" #{join};"
        @mock_connection.should_receive( :create_command ).with( expected_sql_statement ).once.and_return( @mock_command )
        @mock_command.should_receive( :execute )
        @mock_connection.should_receive( :close ).once

        # act
        data_extractor_with_valid_connectivity.extract(ext_options)        
    end

    it 'should ignore missing criteria and execute a query without any where clause' do
        environment = 'development'
        schema = 'public'
        table = 'foo'
        expected_sql_statement = %[select *, 'development' as environment from "#{schema}"."#{table}";]
        @mock_connection.should_receive( :create_command ).with( expected_sql_statement ).once.and_return( @mock_command )
        @mock_command.should_receive( :execute )
        @mock_connection.should_receive( :close ).once

        data_extractor_with_valid_connectivity.extract( :environment => environment, :schema => schema, :source_table => table )
    end    
    
    it "should pass on the supplied column list (in the sql) if the :columns mapping option is present" do
	env = 'dev'
	schema = 'public'
	table = 'foo'
	columns = %w(name address post_code telephone_number)
	expected_sql = %[select #{columns.join( ', ' )}, 'dev' as environment from "#{schema}"."#{table}";]

	@mock_connection.should_receive( :create_command ).with( expected_sql ).once.and_return( @mock_command )
	@mock_command.should_receive( :execute )
	@mock_connection.should_receive( :close ).once

	data_extractor_with_valid_connectivity.extract( 
	    :environment => env, 
	    :schema => schema, 
	    :source_table => table,
	    :columns => columns
	)	
    end
    
    it 'should pass on the correct sql for checking date to the database' do
        current_day = Time.now.strftime("%Y-%m-%d")

        expected_sql_statement = %(select *, 'development' as environment from "public"."bucket" where date('#{current_day}') - date(when_created) = 1;)

        environment, schema, source_table, criteria =
            mapping_properties("development","public", "bucket", %(date('#{current_day}') - date(when_created) = 1))

        ext_options = {
            :environment => environment,
            :schema => schema,
            :source_table => source_table,
            :criteria => criteria
        }

        @mock_connection.should_receive(:create_command).with( expected_sql_statement ).once.and_return( @mock_command )
        @mock_command.should_receive( :execute )
        @mock_connection.should_receive(:close).once

        data_extractor_with_valid_connectivity.extract(ext_options)
    end    

    def mapping_properties _environment, _schema, _source_table, _criteria
        environment = _environment
        schema = _schema
        source_table = _source_table
        criteria = _criteria

        [environment, schema, source_table, criteria]
    end

    def default_mapping_properties
        environment = 'development'
        schema = "public"
        source_table = "some_table"
        criteria = 'when_created = "2007-08-05"'

        [environment, schema, source_table, criteria]
    end
end
