#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Framework
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Endpoints::DatabaseEndpoint ) do

    #TODO: abstract these tests to use a shared spec that deals with argument validation and uri resolution
    
    it_should_behave_like "All tested constructor behaviour"
    
    before :all do
        @clazz = DatabaseEndpoint
        @constructor_args = [ 'endpoint_uri', 'context' ]
    end

    it 'should explode if the scheme is not postgres' do
        bad_uri = URI.parse('lfs://usr/bin/local')
        lambda {
            DatabaseEndpoint.new( bad_uri, dummy )
        }.should raise_error( ArgumentError, "the 'endpoint uri' must conform to the 'postgres' scheme" )
    end

    it 'should silently convert a string uri descriptor into a uri' do
        uri_string = "postgres://localhost:5432/CAT_STAGING?user=user&password=password"
        dummy_uri = dummy( 'someuri ')
        dummy_uri.stub!( :scheme ).and_return( 'postgres' )
        URI.should_receive( :parse ).once.with( uri_string ).and_return( dummy_uri )

        DatabaseEndpoint.new( uri_string, dummy )
    end

    it "should create a disconnected driver on standby for the supplied uri" do
	data_source_uri = URI.parse("postgres://localhost:5432/CAT_STAGING?user=user&password=password")
    	db_connect_options = {
            :host => data_source_uri.host,
	    :port => data_source_uri.port,
	    :catalog => data_source_uri.path.gsub( /\//mix, '' ),
	    :user => 'user',
	    :password => 'password',
	    :disconnected => true
        }
        Database.should_receive(:connect).once.with(db_connect_options).and_return(mock_db=dummy)

	endpoint = DatabaseEndpoint.new(data_source_uri, dummy)
	endpoint.send(:instance_variable_get, "@database").should equal(mock_db)
    end

end

describe given( ETL::Integration::Engine::Endpoints::DirectoryEndpoint ), 'when marhalling exchanges into an endpoint' do

    before :all do
	@uri_string = "postgres://localhost:5432/CAT_STAGING?user=user&password=password"
    end

    it 'should explode on unmarshal' do
	lambda {
	    DatabaseEndpoint.new(@uri_string, dummy).unmarshal()
        }.should raise_error(NotImplementedException)
    end

    it "should ignore exchanges marshalled in unless they have a :command header" do
        exchange = Exchange.new(dummy)
        message = Message.new
        exchange.inbound = message
        expected_output = Message.new
        expected_output.set_header(:noop, nil)

        endpoint = DatabaseEndpoint.new(@uri_string, dummy)
        endpoint.marshal(exchange)
        exchange.outbound.should eql(expected_output)
    end
    
    it "should pass on the SQL in the body of a :command message for execution by a sql command processor" do
        command = Message.new
        command.body = "create table foo(id integer, name varchar(255));"
        command.set_header(:command, :SQL)
        command.set_header(:command_type, :DDL)
        exchange = Exchange.new(dummy)
        exchange.inbound = command
        
        mock_processor = mock 'sql processor'
        SqlCommandProcessor.stub!(:new).and_return(mock_processor) #dummy will ignore connect/disconnect

        mock_processor.should_receive(:process).once.with(exchange)
        
        endpoint = DatabaseEndpoint.new(@uri_string, dummy)
        endpoint.marshal(exchange)
    end
    
end
