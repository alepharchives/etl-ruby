#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'
include BehaviourSupport

describe given(URI), 'when calling the overriden parse method' do

    it "should parse a regular uri using the original parse method" do
        [
            'nfs://usr/bin/local',
            'file://mount/forwardi1/nxtf4/demo.csv',
            'postgres://localhost:3001/CAT_STAGING?user=mis&password=foo#delimited=true',
            'http://www.google.com'
        ].each do |primitive_uri|
            URI.parse(primitive_uri).should be_a_kind_of(URI::Generic)
        end
    end

    it "should resolve to a local file system uri when an 'lfs' string is passed" do
        uri = URI.parse("lfs://usr/bin/local")
        uri.should be_an_instance_of(URI::LFS)
    end

    it "should correctly set the drive letter when specified in the uri string" do
        uri = URI.parse("lfs:/d/program files/mssql/9.1")
        uri.drive.should eql('d')
    end

    it "should work correctly with File.resolve_path" do
        lambda {
            uri = URI.parse("lfs:/#{ENV['STARTUP_PATH']}")
        }.should_not raise_error
    end

    it "should ignore any trailing File::Separator characters" do
        uri =  URI.parse("lfs://usr/bin/local/")
        uri.stub!(:running_on_windows?).and_return(false)
        uri.full_path.should eql("/usr/bin/local/")
    end

end

describe URI::LFS do

    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = URI::LFS
        @constructor_args = [ 'drive', 'path' ]
    end

    it "should resolve the path only, if the drive is not specified" do
        uri = @clazz.new('', "/usr/bin/local")
        uri.stub!(:running_on_windows?).and_return(false)
        uri.full_path.should eql("/usr/bin/local/")
    end

    it "should insert a File::Separator character if the supplied path doesn't contain one and the drive is missing" do
        uri = @clazz.new('', 'usr/bin/local')
        uri.stub!(:running_on_windows?).and_return(false)
        uri.full_path.should eql('/usr/bin/local/')
    end

    it "should resolve the path including the drive letter (and Windows specific drive marker) when the drive is present" do
        uri = @clazz.new('c', 'Documents and settings/600256222/My Music')
        uri.stub!(:running_on_windows?).and_return(true)
        uri.full_path.should eql("c:/Documents%20and%20settings/600256222/My%20Music/")
    end

    it "should not resolve stupid windows path sep characters back to unix style ones" do
        uri = @clazz.new("D", "Work\\Ruby\\Discovery")
        uri.stub!(:running_on_windows?).and_return(true)
        uri.full_path.should eql("D:/Work%5CRuby%5CDiscovery/")
    end

    it "should provide a #to_s method that is aware of drive letters" do
        uri = @clazz.new("F", "xx/dev/workspace")
        uri.stub!(:running_on_windows?).and_return(true)
        uri.to_s.should eql("lfs:/F:/xx/dev/workspace/")
    end

    it "should collapse a missing drive letter into the path when #to_s is called" do
        uri = @clazz.new('', '/media/mount/sdb1/dataext')
        uri.stub!(:running_on_windows?).and_return(false)
        uri.to_s.should eql('lfs://media/mount/sdb1/dataext/')
    end

end
