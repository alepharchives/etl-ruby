# #!/usr/bin/env ruby

require 'rubygems'
require 'spec'
require 'stringio'
require "fastercsv"

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

# ##################################################################################### ##############
# Behaviour Support                     ################
# #####################################################################################

module FileEndpointBehaviourSupport
    def prepare_expectations
        file_endpoint = prepare_default_expectations
        File.stub!(:open).and_return(mock_file=dummy())
        yield file_endpoint, mock_file
    end
    def prepare_default_expectations
        File.stub!(:file?).and_return(true)
        File.stub!(:basename).and_return('mock - basename')
        dummyuri = dummy
        dummyuri.stub!(:scheme).and_return('file')
        dummyuri.stub!(:path).and_return('path')
        endpoint = FileEndpoint.new(dummyuri, dummy)
        converted_uri = dummy
        converted_uri.stub!(:full_path).and_return('path')
        URI.stub!(:parse).and_return(converted_uri)
        return endpoint
    end
end

# ##################################################################################### ##############
# Behaviour Examples                    ################
# #####################################################################################

describe given( ETL::Integration::Engine::Endpoints::FileEndpoint ), 'when initializing a new instance' do

    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = FileEndpoint
        @constructor_args = [ 'endpoint_uri', 'execution_context' ]
    end

    it "should explode if the scheme is not 'file'" do
        bad_uri = URI.parse('postgres://localhost:5432/CAT_STAGING')
        lambda {
            FileEndpoint.new( bad_uri, dummy )
        }.should raise_error( ArgumentError, "the 'endpoint uri' must conform to the FILE scheme" )
    end

    it 'should silently convert a string uri descriptor into a uri' do
        uri_string = 'lfs://myshare1/myfolder/mysubdirectory'
        dummy_uri = dummy( 'someuri ')
        dummy_uri.stub!( :scheme ).and_return( 'file' )
        dummy_uri.stub!( :path ).and_return( 'foo' )
        dummy_uri.stub!( :to_s ).and_return( uri_string )
        File.stub!( :file? ).and_return( true )

        URI.should_receive( :parse ).once.with( uri_string ).and_return( dummy_uri )

        FileEndpoint.new( uri_string, dummy )
    end
    
    it "should deal with inconsistent file:// uri handlers" do
        File.should_receive(:file?).with("D:/xx/dev/workspace/pe-sdk-mis/etl4r/test/integration/data/prebuilt/logs/sourcefile.log").and_return(true)
        File.stub!(:open).and_return(dummy)
        uri = "file:/D:/xx/dev/workspace/pe-sdk-mis/etl4r/test/integration/data/prebuilt/logs/sourcefile.log"
        endpoint = FileEndpoint.new(uri, dummy)
        endpoint.stub!(:running_on_windows?).and_return(true)
        lambda {
            endpoint.unmarshal()
        }.should_not raise_error
    end
    
end

describe given( ETL::Integration::Engine::Endpoints::FileEndpoint ), 'when pulling exchanges out of an endpoint' do

    include FileEndpointBehaviourSupport

    it "should return an exchange for each line in the underlying I/O object" do
        expected_lines = [ "one", "two" ]
        prepare_expectations do |file_endpoint, mock_file|
            mock_file.stub!(:eof?).and_return(false, false, true)
            mock_file.stub!( :gets ).and_return( "one", "two" )
            2.times{
                file_endpoint.unmarshal().should_not be_nil
            }
        end
    end

    it "should close the file even if an exception is thrown" do
        prepare_expectations do |file_endpoint, mock_file|
            mock_file.stub!( :eof? ).and_return(false)
            mock_file.stub!( :gets ).and_raise(IOError)
            mock_file.should_receive( :close ).once
            lambda{
                file_endpoint.unmarshal
            }.should raise_error
        end
    end

    it "should not try and close the file if open throws an exception" do
        prepare_expectations do |file_endpoint, mock_file|
            File.stub!( :open ).and_raise(IOError)
            lambda{
                file_endpoint.unmarshal
            }.should raise_error(IOError)
        end
    end

    it "should track the file offset between method calls" do
        text=<<-EOS
	    one
	    two
	    six
        EOS
        string_io = StringIO.new( text )
        expected_results = (1..3).to_a.collect { |elem| string_io.gets() }
        string_io.seek(0)
        prepare_expectations do |file_endpoint, mock_file|
            [ :eof?, :gets, :pos ].each do |delegated_method|
                mock_file.should_receive(delegated_method).at_least(3).times do
                    string_io.send(delegated_method)
                end
            end
            mock_file.should_receive(:seek).exactly(3).times { |pos| string_io.seek(pos) }

            3.times {
                message = file_endpoint.unmarshal().outbound
                message.body.should eql( expected_results.shift() )
                message.headers[:offset].should eql(string_io.pos)
            }
        end
    end

    it "should stop serving data once all the lines have been returned" do
        prepare_expectations do |ep, file|
            file.stub!(:eof?).and_return(false, true)
            file.stub!(:gets).and_return('foo')
            ep.unmarshal().should_not be_nil
            3.times { ep.unmarshal().should be_nil }
        end
    end

    it "should begin serving data again after receiving a 'reset' command" do
        prepare_expectations do |ep, file|
            file.stub!(:eof?).and_return(false, true, true, true, false)
            file.stub!(:gets).and_return('foo', 'foo')
            ep.unmarshal().should_not be_nil
            3.times { ep.unmarshal().should be_nil }
            ep.reset()
            ep.unmarshal().should_not be_nil
        end
    end
    
   it "should resolve an ambiguous host name on unix based systems" do
        exchange = Exchange.new(dummy)
        message = Message.new()
        message.body = "foo bar baz"
        exchange.outbound = message
        
        path = "/home/watsont9/test/etl4r/test/integration/data/prebuilt/logs/sourcefile.log"
        odd_uri = "file:/#{path}"
        endpoint = FileEndpoint.new(odd_uri, dummy)
        endpoint.stub!(:running_on_windows?).and_return(false)
        
        File.stub!(:file?).and_return(true)
        File.should_receive(:open).with(path, 'r').and_return(dummy)
        
        endpoint.unmarshal()
    end     
    
end

describe given( ETL::Integration::Engine::Endpoints::FileEndpoint ), 'when processing exchanges sent to an endpoint' do

    include FileEndpointBehaviourSupport

    it "should set a fault on the exchange if the body of the supplied input channel is nil" do
        exchange = Exchange.new(dummy)
        exchange.inbound = Message.new
        prepare_expectations do |endpoint, io|
            io.should_not_receive(:puts)
            endpoint.marshal(exchange)
            exchange.should have_fault
            fault = exchange.fault
            fault.headers[:fault_code].should eql(FaultCodes::MissingMessageBody) #TODO: FaultCodes module with const members for all our fault codes
            fault.headers[:fault_description].should be_an_instance_of(String)
        end
    end

    it "should write the message body (when present) to the underlying file" do
        exchange = Exchange.new(dummy)
        input = Message.new
        input.body = input_message = "The quick brown fox..."
        exchange.inbound = input
        prepare_expectations do |endpoint, io|
            io.should_receive(:puts).once.with(input_message)
            endpoint.marshal(exchange)
        end
    end

    it "should write using fastercsv instead of the standard ruby File class" do
        exchange = Exchange.new(dummy)
        input = Message.new
        delim = '|'
        input.set_header(:delimiter, delim)
        input.body = input_message = %w(a b c d e f g)
        exchange.inbound = input
        endpoint = prepare_default_expectations
        endpoint.stub!(:running_on_windows?).and_return(false)

        FasterCSV.should_receive(:open).with(anything(), 'a', {:col_sep => delim}).and_return(mockio=dummy('io'))
        mockio.should_receive(:puts).once.with(input_message)
        endpoint.marshal(exchange)
    end

    #TODO: URGENT: reconsider this
    it "should correctly resolve a file uri with an ambiguous host name" do
        # prepare
        context = ExecutionContext.new()
        exchange = Exchange.new(context)
        message = Message.new
        message.body = "foo bar baz"
        exchange.inbound = message
        path = "/opt/cruisecontrolrb-1.1.0/projects/etl4r/work/test/integration/data/logs/capability_usage.log"
        endpoint = FileEndpoint.new("file://#{path}", context)
        endpoint.stub!(:running_on_windows?).and_return(false)
        # expectations
        File.should_receive( :open ).with( path, "a" ).and_return( dummy )

        # act
        endpoint.marshal(exchange)
    end

    it "should correctly figure out that a windows box requires a drive letter (or 'host')" do
        context = ExecutionContext.new()
        exchange = Exchange.new(context)
        message = Message.new()
        message.body = "foo bar baz"
        exchange.inbound = message
        odd_uri = "file://D/xx/dev/workspace/pe-sdk-mis/etl4r/test/integration/data/logs/new_session.log"
        endpoint = FileEndpoint.new(odd_uri, context)
        endpoint.stub!(:running_on_windows?).and_return(true)

        File.should_receive(:open).with("D:/xx/dev/workspace/pe-sdk-mis/etl4r/test/integration/data/logs/new_session.log", 'a').and_return(dummy)

        endpoint.marshal(exchange)
    end  
    
    #TODO: don't throw here, but set fault instead....

    it "should close the file even if there is an exception" do
        exchange = Exchange.new(dummy)
        input = Message.new
        delim = '|'
        input.set_header(:delimiter, delim)
        input.body = input_message = %w(a b c d e f g)
        exchange.inbound = input
        endpoint = prepare_default_expectations

        FasterCSV.stub!(:open).and_return(mockio=dummy('io2'))
        mockio.stub!(:puts).and_raise(IOError)
        mockio.should_receive( :close )

        lambda {
            endpoint.marshal(exchange)
        }.should raise_error
    end
    
end
