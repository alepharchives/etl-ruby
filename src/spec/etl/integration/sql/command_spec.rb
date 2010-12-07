#!/usr/bin/env ruby

require 'rubygems'
require 'spec'
require 'postgres'

require File.dirname(__FILE__) + '/../../../spec_helper'

include BehaviourSupport
include MIS::Framework

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::SQL::DatabaseCommand ), "when used to abstract a given sql statement/command" do

    before :each do
        @mock_database_driver = mock 'database'
        PostgresPR::Connection.should_receive( :new ).with( any_args ).and_return( @mock_database_driver )
        @dummy_result_set = mock 'resultset'
        @database = Database.connect $config.connection_properties
    end

    it 'should set the command text to the requested sql query' do
        expected_query = 'select * from foo;'
        command = @database.create_command expected_query
        command.command_text.should eql( expected_query )
    end

    it 'should pass on the supplied command text to the driver' do
        expected_query = 'select * from information_schema.columns limit 10;'
        @mock_database_driver.should_receive( :query ).once.with( expected_query )
        command = @database.create_command expected_query
        command.execute
    end

    it 'should pass on any supplied parameter arguments to the query' do
        sql_statement=<<-SQL
            insert into table_foo ( name, age, description )
            values ( ?, ?, ? );
        SQL
        expected_query=<<-SQL
            insert into table_foo ( name, age, description )
            values ( 'flobber', 25, 'floober-ish' );
        SQL
        local_variables.each { |sql_string| eval( "#{sql_string}=#{sql_string}.trim_lines" ) }

        @mock_database_driver.should_receive( :query ).once.with( expected_query.join( $/ ) )

        command = @database.create_command sql_statement
        command.execute 'flobber', 25, 'floober-ish'
    end

    it 'should compile a named execution plan for future use' do
        sql_statement=<<-SQL
            select *
            from products
            where product_id like ?;
        SQL

        command = @database.create_command sql_statement

        expected_plan=<<-SQL
            prepare etl4r_plan_#{command.object_id.to_s.gsub(/-/, '')} as
            select *
            from products
            where product_id like $1;
        SQL
        expected_query=<<-SQL
            execute etl4r_plan_#{command.object_id.to_s.gsub(/-/, '')}( '@sb-domain.com' );
        SQL
        expected_remove_plan=<<-SQL
            deallocate etl4r_plan_#{command.object_id.to_s.gsub(/-/, '')};
        SQL
        local_variables.each do |sql_string|
                eval( "#{sql_string}=#{sql_string}.trim_lines if #{sql_string}.kind_of? String" )
        end

        ordered_expected_statements = [
            expected_plan,
            expected_query,
            expected_remove_plan
        ].collect { |sql| sql.join( $/ ) }

        @mock_database_driver.should_receive( :query ).exactly( 3 ).times do |actual_statement, compat|
            actual_statement.should eql( ordered_expected_statements.shift )
        end
        @mock_database_driver.should_receive( :close )

        command.prepare!            #prepare_execution_plan
        command.execute '@sb-domain.com'   #execute cached statement
        @database.disconnect        #implicitly calls dispose
    end

end
