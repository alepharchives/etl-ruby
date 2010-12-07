# #!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine
include MIS::Framework

# ##################################################################################### ##############
# Behaviour Examples                    ################
# #####################################################################################

describe given( ETL::Integration::Engine::Processors::SqlBulkLoaderProcessor ) do

    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = SqlBulkLoaderProcessor
        @constructor_args = [ ]
    end
    
    before :each do
        @msg = Message.new
        @msg.body = "foo bar baz"
        @msg.set_header(:table_name, 'abc')
        @msg.set_header(:db_uri, 'abc')
        @msg.set_header(:delimiter, '|')
        @mock_context = mock 'mock_context'

        @db_uri = Hash.new
        @db_uri[:host] = 'localhost'
        @db_uri[:port] = '1234'
        @db_uri[:catalog] = 'database_does_not_exist'
        @db_uri[:user] = 'some_user'
        @db_uri[:password] = 'password'
        make_hash_callable(@db_uri)        
        @conn_str = "postgres://localhost:1234/database_does_not_exist?user=some_user&password=password"
        props = {
            :connection_properties => @db_uri,
            :connection_string => @conn_str
        }
        make_hash_callable(props)        
        @mock_context.stub!(:config).and_return(props)
        
        @exchange = Exchange.new(@mock_context)
        @exchange.inbound = @msg 
        @processor = SqlBulkLoaderProcessor.new
    end
    
    it "should explode if database configuration is not supplied" do
        context = dummy
        context.stub!(:config).and_return(dummy)
        exchange = Exchange.new(context)
        exchange.inbound = @msg
        
        # act
        @processor.process( exchange )

        # assert
        exchange.fault.headers[:fault_code].should eql(:invalid_payload) 
        
    end
    
    it "should explode if not supplied a dump file to load in path header" do
        # act
        @msg.set_header(:path, nil)
        @processor.process( @exchange )

        # assert
        @exchange.fault.headers[:fault_code].should eql(:invalid_payload)      
        
    end
    
    it "should explode if not supplied a table to load into in message header" do               

        # act
        @msg.set_header(:table_name, nil)
        @processor.process( @exchange )

        # assert
        @exchange.fault.headers[:fault_code].should eql(:invalid_payload)     
        
    end
    
    it "should load contents of file into database table" do
        table = 'LDAP_Raw'
        file = 'file.csv'
        delimiter = '|'
        columns = []
        
        mock_connection = mock( 'connection' )        
        Database.should_receive(:connect).with(@db_uri).and_return(mock_connection)
        mock_connection.should_receive(:schema=)
        mock_connection.should_receive(:get_column_metadata).with(table).and_return(columns)
        
        sql_bulk_loader = dummy
        SqlBulkLoader.should_receive(:new).with(@conn_str).and_return(sql_bulk_loader)
        sql_bulk_loader.should_receive(:load).with(:file_uri => file,
            :delimiter => delimiter,
            :mapping_rules => {
                :table => table,
                :columns => columns
            })
                
        @msg.set_header(:path, file)
        @msg.set_header(:table_name, table)
        @msg.set_header(:db_uri, @db_uri)
        @msg.set_header(:delimiter, delimiter)
        
        # act
        @processor.process( @exchange )

        # assert
        response = @exchange.outbound.headers[:response]
        response.should eql("#{file} contents successfully loaded into #{table}.")
    end
        
end