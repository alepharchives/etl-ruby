#!/usr/bin/env ruby

require 'rubygems'
require 'net/ldap'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../../") + '/spec_helper'

include BehaviourSupport
include MIS::Framework

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe 'Any ldap extract', :shared => true do

    before :all do
        #note: DataAdapter's connection factory-esque behaviour requires
        #    you to extend the module yourself. See the rdoc comments for details.

        module ETL
            module Integration
                module DataAdapter
                    @@supported_drivers = {
                        :ldap => {
                            :package_name => 'net/ldap',
                            :class_name => 'Net::LDAP',
                            :method_name => 'new'
                        }
                    }
                end
            end
        end
        @treebase = "ou=Applications,dc=sdk,dc=xx,dc=com"
        @authorization = { :method => :anonymous }
    end

    def dummy_entry
        entry = DummyEntry.new
        entry.uid = 'urn:uuid:0c3bb031-08b6-4f77-b14f-c6bcaee6a438'
        entry.mail = 'tim.watson@sb-domain.com'
        entry.cn = 'TimsDemoApp'
        entry.member = 'cn=SDKExternal,ou=Groups,dc=sdk,dc=xx,dc=com'
        entry
    end

    def setup_expectations_for( filter )
        @mock_ldap.should_receive( :search ).once.with(
            :base => @treebase,
            :filter => filter,
            :attr => ["cn", "mail"],
            :attrsonly => true
        )
    end

    def extract_and_expect( *args )
        filter = args[0] unless args.nil?
        adapter = ETL::Integration::Extraction::LdapExtractor.new 'ldap://quarantine.nat.xx.com:389'
        adapter.extract(
            :treebase => @treebase,
            :filter => filter,
            :attr => ["cn", "mail"]
        )
        if block_given?
            yield adapter
        end
        adapter
    end
end

describe given( ETL::Integration::Extraction::LdapExtractor ), 'when connecting to an LDAP respository' do
    it 'should explode if given an invalid uri' do
        bad_uri = 'http://www.google.com'
        adapter = ETL::Integration::Extraction::LdapExtractor.new bad_uri
        lambda do
            adapter.extract(
                :treebase => @treebase,
                :filter => nil,
                :attr => ["cn", "mail"]
            )
        end.should raise_error( ConnectivityException )
    end
end

describe given( ETL::Integration::Extraction::LdapExtractor ), 'when performing an extract' do

    it_should_behave_like 'Any ldap extract'

    [ :treebase, :filter, :attr ].each do |required_argument|
        it "should validate the presence of the #{required_argument} argument during a call to extract" do
            attrs = [ "cn", "mail" ]
            filter = Net::LDAP::Filter.eq( 'cn', 'mail' )
            options = eval <<-EOF
            {
                    #{':treebase => @treebase,' unless required_argument == :treebase}
                    #{':filter=> filter,' unless required_argument == :filter}
                    #{':attr => attrs' unless required_argument == :attr}
            }
            EOF
            filter = Net::LDAP::Filter.eq( 'cn', '*-sdk' )
            #setup_expectations_for( filter )
            lambda {
                adapter = ETL::Integration::Extraction::LdapExtractor.new 'ldap://quarantine.nat.xx.com:389'
                adapter.extract( options )
            }.should raise_error( ArgumentError )
        end
    end

end

describe given( ETL::Integration::Extraction::LdapExtractor ), 'when connected to an LDAP repository' do

    it_should_behave_like 'Any ldap extract'

    before :each do
        @mock_filter = mock( 'Filter' )
        @mock_ldap = mock( 'LDAP' )
        Net::LDAP::Filter.stub!( :eq ).and_return( @mock_filter )
        Net::LDAP.should_receive( :new ).once.with(
            :host => 'quarantine.nat.xx.com',
            :port => 389,
            :auth => @authorization
        ).and_return( @mock_ldap )
    end

    it 'should pass on only the options supplied to extract' #todo: think about this twice

    it 'should wrap any underlying errors in DataAccessException'

    #do
    #    filter = Net::LDAP::Filter.eq( 'cn', 'foobar' )
    #    setup_expectations_for( filter ).and_raise( StandardError )
    #    lambda do
    #        extract_and_expect( filter )
    #    end.should raise_error( DataAccessException )
    #end

    #todo: think about creating a criteria API to use instead of Net::LDAP::Filter

    it 'should extract data when given a valid filter expression' do
        filter = Net::LDAP::Filter.eq( 'cn', '*' )
        entry = dummy_entry
        setup_expectations_for( filter ).and_yield( entry )
        extract_and_expect( filter ).dataset.should include( entry )
    end

    it 'should not extract data when given an invalid filter expression' do
        filter = Net::LDAP::Filter.eq( 'cn', 'foobar' )
        setup_expectations_for( filter )
        extract_and_expect( filter ).dataset.should be_empty
    end

end
