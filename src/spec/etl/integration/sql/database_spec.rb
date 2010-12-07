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

describe "All database behaviour", :shared => true do

    before :each do
        @mock_database_driver = mock 'database'
        PostgresPR::Connection.should_receive( :new ).with( any_args ).and_return( @mock_database_driver )
        @dummy_result_set = mock 'resultset'
        @database = Database.connect $config.connection_properties
    end

    def set_expectations_on_underlying_database_driver
        yield @database if block_given?
    end

end

describe given( ETL::Integration::SQL::Database ), 'when connecting to a postgres database' do

    it_should_behave_like "All database behaviour"
    
    it 'should be connected initially' do
        @database.should be_connected
    end
    
    it 'should disconnect properly when requested to do so' do
        @mock_database_driver.should_receive( :close ).once
        lambda {
            @database.disconnect
        }.should change( @database, :connected? ).to( false )
    end   
    
end

describe given( ETL::Integration::SQL::Database ), 'when handling boundary conditions' do

    it 'should explode with a connectivity exception when the underlying driver fails to connect' do
        connect_error_message = 'connect(2)'
        connect_error = Errno::EBADF.new( connect_error_message )
        PostgresPR::Connection.should_receive( :new ).once.with( any_args ).and_raise( connect_error )
        lambda {
            Database.connect $config.connection_properties
        }.should raise_error( ConnectivityException, "FATAL ERROR: unable to establish connection. #{connect_error.message}" )
    end
    
    it 'should explode with a useful error message when underlying driver fails to connect and supplies an error code' do
        connect_error_message = "FATAL	C3D000	Mdatabase \"CAT_STAGING\" does not exist	Fpostinit.c	L318	RInitPostgres"
        connect_error = RuntimeError.new( connect_error_message )
        PostgresPR::Connection.should_receive( :new ).once.with( any_args ).and_raise( connect_error )
        lambda {
            Database.connect( $config.connection_properties )
        }.should raise_error( ConnectivityException, "C3D000: unable to establish connection. database \"CAT_STAGING\" does not exist" )
    end
    
    [
        RuntimeError.new,
        StandardError.new,
        SystemCallError.new( '' )
    ].each do |exception_object|
        it "should wrap any #{exception_object.class} in the driver, with a data access exception" do
            PostgresPR::Connection.should_receive( :new ).once.with( any_args ).and_raise( exception_object )
            lambda {
                Database.connect( $config.connection_properties )
            }.should raise_error( DataAccessException )
        end
    end
    
end

describe given( ETL::Integration::SQL::Database ), 'when executing a sql command' do

    it_should_behave_like "All database behaviour"

    it 'should provide inline execution of a command' do
        sql_statement = "select * from foo where bar > 10;"
        mock_command = mock 'dbcommand'
        DatabaseCommand.stub!( :new ).and_return( mock_command )
        mock_command.should_receive( :execute ).once
        @database.execute_command sql_statement
    end
    
    {
        'select count(*) as value from table_foo;' => 10,
        'select customer_last_name as value from customers where id = 1234;' => 'Jones'
    }.each do |query, result|
        it "should return a scalar value from a scalar query, such as '#{query}'" do
            columns = [
                mock( 'column' )
            ]
            columns.first.should_receive( :name ).once.and_return( :value )
            rows = [
                mock( 'row' )
            ]
            rows.first.should_receive( :value ).and_return( result )
            
            resultset = mock 'resultset'
            resultset.should_receive( :columns ).once.times.and_return( columns )
            resultset.should_receive( :rowcount ).twice.and_return( rows.size )
            resultset.should_receive( :rows ).and_return( rows )
            
            @database.stub!( :connect )
            @database.should_receive( :execute ).once.with( query ).and_return( resultset )
            @database.execute_scalar( query ).should eql( result )
        end
    end
    
    it 'should explode if a non scalar query is passed to execute scalar' do
        resultset = mock 'rs'
        resultset.should_receive( :rowcount ).twice.and_return( 15 )
        
        @database.stub!( :connect )
        @database.stub!( :execute ).and_return( resultset )
        lambda {
            @database.execute_scalar( 'select count(*) from empty_table;' )
        }.should raise_error( InvalidOperationException, "excecute_scalar can not return multiple rows"  )
    end
    
    it 'should return nil if a scalar query returns an empty resultset' do
        resultset = mock 'rs'
        resultset.should_receive( :rowcount ).and_return( 0 )
        
        @database.stub!( :connect )
        @database.stub!( :execute ).and_return( resultset )
        @database.execute_scalar( 'select count(*) from empty_table;' ).should be_nil
    end

end

describe given( ETL::Integration::SQL::Database ), 'when fetching catalog meta data' do

    it_should_behave_like "All database behaviour"

    it 'should return a list of column names for the given table on demand' do
        expected_sql_statement =<<-SQL
            select column_name
            from information_schema.columns
            where
                table_schema = 'public' and
                table_catalog = 'CAT_STAGING' and
                table_name = 'foo'
            order by ordinal_position;
        SQL
        after_setup_expectations( expected_sql_statement ) do |column_names|
            @database.get_column_metadata( table_name='foo' ).should eql( column_names )
        end
    end

    it 'should exclude the schema mapping condition if @schema is not specified on the database adapter' do
        expected_sql_statement =<<-SQL
            select column_name
            from information_schema.columns
            where
                table_schema = 'pgdefault' and
                table_catalog = 'CAT_STAGING' and
                table_name = 'foo'
            order by ordinal_position;
        SQL
        @database.schema = 'pgdefault'
        after_setup_expectations( expected_sql_statement ) do |column_names|
            @database.get_column_metadata( table_name='foo' ).should eql( column_names )
        end
    end
    
    it 'should return a record count for a given table on demand' do
        expected_sql_statement = "select coalesce(count(*), 0) as count from table_foo;"
        expected_count = 10
        set_expectations_on_underlying_database_driver do |driver|
            driver.should_receive( :execute_scalar ).once.with( expected_sql_statement ).and_return( expected_count )
        end
        @database.get_table_rowcount( 'table_foo' ).should eql( expected_count )
    end

    def after_setup_expectations( expected_sql_statement )
        expected_sql_statement = expected_sql_statement.trim_tabs
        column_names = [ 'foo', 'bar', 'baz' ]
        col_name_mapping_mocks = column_names.collect do |cn|
            col = mock( cn )
            col.should_receive( :column_name ).and_return( cn )
            col
        end
        set_expectations_on_underlying_database_driver do |driver|
            driver.should_receive( :execute ).once.with( expected_sql_statement ).and_return( col_name_mapping_mocks )
        end
        yield column_names
    end

end

describe given( ETL::Integration::SQL::Database ), 'when executing a sql command within a database transaction' do

    it_should_behave_like "All database behaviour"

    it 'should perform each executable statement within its own transaction by default' do
        @mock_database_driver.should_receive( :query ).exactly( 2 ).times.with( any_args )
        @database.perform {
            @database.execute_command "insert into foo( name, date ) values ( 'tim', null );"
            @database.execute_command "delete from foo where name = 'tim' and date = null;"
        }
    end

    it 'should perform all executable statements within a single transaction if auto_commit_transactions is set to false' do
        begin_transaction = 'begin;'
        statement_one = 'select * from table1;'
        statement_two = 'insert into table2( a, b, c ) values ( 1, 2, 3 );'
        rollback_transaction = 'rollback;'

        ordered_expected_statements = [
            begin_transaction,
            statement_one,
            statement_two,
            rollback_transaction
        ]

        @mock_database_driver.should_receive( :query ).exactly( 4 ).times do |actual_statement, compat|
            actual_statement.should eql( ordered_expected_statements.shift )
            if actual_statement.starts_with? 'insert'
                @database.instance_eval do
                    raise StandardError, 'bang!'
                end
            end
        end
        @mock_database_driver.should_not_receive( :close )

        @database.auto_commit_transactions = false
        lambda do
            @database.perform { |driver|
                driver.execute_command statement_one
                driver.execute_command statement_two
                driver.close
            }
        end.should raise_error( DataAccessException )
    end

    it 'should commit a running transaction if no error occurs within the /perform/ block' do
        begin_transaction = 'begin;'
        sql_statement = "delete from foo where name like 'tim';"
        commit_transaction = 'commit;'

        ordered_expected_statements = [
            begin_transaction,
            sql_statement,
            commit_transaction
        ]

        @mock_database_driver.should_receive( :query ).exactly( 3 ).times do |actual_statement, compat|
            actual_statement.should eql( ordered_expected_statements.shift )
        end

        @database.auto_commit_transactions = false
        @database.perform {
            @database.execute_command sql_statement
        }
    end

    ['begin', 'commit', 'rollback'].each do |cmd|
        it "should forward the '#{cmd}' command to underlying driver" do
            @mock_database_driver.should_receive( :query ).once.with(cmd + ";")
            @database.send "#{cmd}_transaction"
        end
    end

end
