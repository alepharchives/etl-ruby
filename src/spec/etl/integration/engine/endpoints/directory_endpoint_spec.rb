#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::Endpoints::DirectoryEndpoint ), 'when initializing a new instance' do

#    it 'should explode if the supplied uri is nil' do
#        lambda {
#            DirectoryEndpoint.new( nil )
#        }.should raise_error( ArgumentError, "the 'endpoint uri' argument cannot be nil" )
#    end

    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = DirectoryEndpoint
        @constructor_args = [ 'endpoint_uri', 'execution_context' ]
    end

    it 'should explode if the scheme is not lfs' do
        bad_uri = URI.parse('postgres://localhost:5432/CAT_STAGING')
        lambda {
            DirectoryEndpoint.new( bad_uri, dummy )
        }.should raise_error( ArgumentError, "the 'endpoint uri' must conform to the LFS scheme" )
    end

    it 'should silently convert a string uri descriptor into a uri' do
        uri_string = 'lfs://myshare1/myfolder/mysubdirectory'
        dummy_uri = dummy( 'someuri ')
        dummy_uri.stub!( :scheme ).and_return( 'lfs' )
        dummy_uri.stub!( :full_path ).and_return( 'foo' )
        dummy_uri.stub!( :to_s ).and_return( uri_string )
        File.stub!( :directory? ).and_return( true )

        URI.should_receive( :parse ).once.with( uri_string ).and_return( dummy_uri )

        DirectoryEndpoint.new( uri_string, dummy )
    end

    it 'should explode unless the supplied uri can be resolved' do
        unresolvable_uri = URI.parse( 'lfs://foo/bar' )
        unresolvable_uri.stub!(:running_on_windows?).and_return(false)
        lambda {
            DirectoryEndpoint.new( unresolvable_uri, dummy )
        }.should raise_error( UnresolvableUriException, "Unable to resolve uri #{unresolvable_uri}." )
    end

end

describe given( ETL::Integration::Engine::Endpoints::DirectoryEndpoint ), 'when pulling exchanges out of an endpoint' do

    it 'should return a data exchange for each entry in the underlying directory' do

        imaginary_lfs_uri = "lfs://usr/bin/local/docs"
        uri = URI.parse( imaginary_lfs_uri )
        File.stub!( :directory? ).and_return( true )
        valid_entries = [ 'foo', 'bar' ]
        directory_entries = [ '.', '..' ] + valid_entries.dup
        Dir.stub!( :entries ).and_return( directory_entries )

        expected_messages = valid_entries.collect do |next_entry|
            path = File.join(imaginary_lfs_uri, next_entry)
            next_uri = URI.parse( path )
            next_uri.stub!(:eql?).and_return(true) #A neccessary hack, honest! :P
            msg = Message.new
            msg.set_header( :origin, uri )
            msg.set_header( :uri, next_uri )
            msg.set_header( :basename, next_entry )
            msg.set_header( :scheme, next_uri.scheme )
            msg.set_header( :path, next_uri.full_path )
            msg
        end

        context = dummy
        endpoint = DirectoryEndpoint.new( uri, context )
        2.times {
            exchange = endpoint.unmarshal()
            exchange.context.should equal(context)
            expected = expected_messages.shift()
            #puts "expected = #{expected.headers.inspect}"
            #puts "outbound = #{exchange.outbound.headers.inspect}"
            exchange.outbound.headers[:path].should eql( expected.headers[:path] )
        }
    end

    it "should combine the directory path with the entry basename to construct the :path header" do
        uri = URI.parse "lfs://usr/bin/local/"
        uri.stub!(:running_on_windows?).and_return(false)
        File.stub!(:directory?).and_return(true)
        File.stub!(:file?).and_return(true)
        entries = [ 'myfile.csv' ]
        Dir.stub!(:entries).and_return(entries)

        context = dummy
        endpoint = DirectoryEndpoint.new(uri, context)
        endpoint.stub!(:running_on_windows?).and_return(false)
        exchange = endpoint.unmarshal()
        #TODO: reconsider this!?
        exchange.outbound.headers[:path].should eql("/usr/bin/local/myfile.csv")
        exchange.outbound.headers[:basename].should eql("myfile.csv")
    end

    it 'should stop unmarshalling once it has served up all the contents of the underlying directory' do
        uri = get_prepared_uri
        endpoint = DirectoryEndpoint.new( uri, dummy )
        endpoint.stub!(:running_on_windows?).and_return(false)
        2.times{ endpoint.unmarshal() }
        endpoint.unmarshal().should be_nil
    end

    it "should begin serving data again after receiving a 'reset' command" do
        uri = get_prepared_uri
        endpoint = DirectoryEndpoint.new( uri, dummy )
        endpoint.stub!(:running_on_windows?).and_return(false)
        2.times { endpoint.unmarshal() }
        endpoint.reset()
        2.times { endpoint.unmarshal().should_not be_nil }
    end

    it "should insert a semi-colon between the host and path for a windows box" do
        path = "d:/foo/bar/baz"
        uri = URI.parse("lfs:/#{path}")
        uri.stub!(:running_on_windows?).and_return(true)
        File.stub!(:directory?).and_return(true)
        File.stub!(:file?).and_return(true)
        Dir.stub!( :entries ).and_return( [ "file.txt" ] )
        endpoint = DirectoryEndpoint.new(uri, dummy)
        endpoint.stub!(:running_on_windows?).and_return(true)
        exchange = endpoint.unmarshal()
        exchange.outbound.headers[:path].should eql( "#{path}/file.txt" )
    end

    it "should ensure that the path of any outgoing uri (e.g. a 'file' URI) is correctly formatted on windows systems" do
        path = "D:/xx/dev/workspace/pe-sdk-mis/etl4r/test/integration/data/logs/"
        uri = URI.parse("lfs:/#{path}")
        uri.stub!(:running_on_windows?).and_return(true)
        File.stub!(:directory?).and_return(true)
        File.stub!(:file?).and_return(true)
        Dir.stub!(:entries).and_return( [ 'old_session.log' ] )
        endpoint = DirectoryEndpoint.new(uri, dummy)
        endpoint.stub!(:running_on_windows?).and_return(true)
        exchange = endpoint.unmarshal()
        exchange.outbound.headers[:path].should eql("#{path}old_session.log")
    end

    it "should not insert a host into the uri on unix based systems..."

    def get_prepared_uri
        uri = URI.parse "lfs://usr/bin/application1"
        File.stub!( :directory? ).and_return( true )
        two_subdirectories = [ '.', '..', 'a', 'b' ]
        Dir.stub!( :entries ).and_return( two_subdirectories.dup, two_subdirectories.dup )
        return uri
    end

end
