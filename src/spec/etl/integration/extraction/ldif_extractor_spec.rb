#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path( File.dirname( __FILE__ ) + '/ldif_extract_test_data' )
require File.expand_path("#{File.dirname(__FILE__)}/../../../")  + '/spec_helper'
include BehaviourSupport

include MIS::Framework

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Extraction::LdifExtractor ) do

    before :each do
        File.stub!( :file? ).and_return true
    end

    it 'should explode if given an invalid file uri' do
        File.should_receive( :file? ).and_return false
        lambda do
            LdifExtractor.new 'no_such_file.ldif'
        end.should raise_error( InvalidOperationException )
    end

    it 'should produce no output if file is empty' do
        extract_from_empty_file.dataset.should be_empty
    end

    it 'should fail if we try to modify after extraction' do
        lambda do
            extract_from_empty_file.dataset.push nil
        end.should raise_error
    end

    it 'should return a correctly populated entry for any supplied ldap data' do
        expected_entry = get_valid_expected_test_entry
        extractor = LdifExtractor.new 'emptyfile.ldif'
        extractor.extract
        extractor.dataset.should include( expected_entry )
    end

    it 'should return multiple valid entries if present' do
        File.stub!( :readlines ).and_return( $file_with_two_entries.split( "\n" ) )
        extractor = LdifExtractor.new 'dummy_file_uri.ldif', 'Sandbox'
        extractor.extract
        extractor.dataset.size.should eql( 2 )
    end

    def extract_from_empty_file
        File.stub!( :readlines ).and_return []
        extractor = LdifExtractor.new 'emptyfile.ldif'
        extractor.extract
        extractor
    end

    def get_valid_expected_test_entry
        expected_entry = LdifEntry.new
        expected_entry.uid = 'urn:uuid:a4739e66-191f-4da6-affe-abfa2158ddd1'
        expected_entry.mail = 'sdkportal@sb-domain.com'
        expected_entry.cn = 'NathansNewApp13'
        expected_entry.member = 'cn=SDKExternal,ou=Groups,dc=sdk,dc=xx,dc=com'
        expected_entry.applicationEnabled = 'FALSE'
        expected_entry.disableReason = 'Application Is Not Enabled'
        expected_entry.environment = 'Sandbox'

        expected_lines = <<-EOF
            # extended LDIF
            #
            # LDAPv3
            # base <dc=sdk,dc=xx,dc=com> with scope sub # filter: (objectclass=*) # requesting: ALL #

            # sdk.xx.com
            dn: dc=sdk,dc=xx,dc=com
            objectClass: top
            objectClass: dcObject
            objectClass: organization
            o: XX
            dc: sdk

            # urn:uuid:a4739e66-191f-4da6-affe-abfa2158ddd1, Applications, sdk.xx.com
            dn:
            uid=urn:uuid:a4739e66-191f-4da6-affe-abfa2158ddd1,ou=Applications,dc=sdk,d
             c=xx,dc=com
            owner: cn=sdkportal@sb-domain.com,ou=People,dc=sdk,dc=xx,dc=com
            applicationEnabled: #{expected_entry.applicationEnabled}
            mail: #{expected_entry.mail}
            uid: #{expected_entry.uid}
            disableReason: #{expected_entry.disableReason}
            objectClass: top
            objectClass: SdkApplication
            objectClass: uidObject
            member: #{expected_entry.member}
            cn: #{expected_entry.cn}
        EOF

        File.stub!( :readlines ).and_return expected_lines.trim_lines
        expected_entry
    end

end
