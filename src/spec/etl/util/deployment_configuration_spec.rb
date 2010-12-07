#!/usr/bin/env ruby

require 'rubygems'
require 'spec'
require 'yaml'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'
include BehaviourSupport

include ETL

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::DeploymentConfiguration ), 'when included in a consumer class' do

    before :each do
        @user = 'user'
        @password = 'password'
        @host = 'host'
        @port = 'port'
        @catalog = 'catalog'
        File.stub!( :open ).and_return( nil )
        YAML.stub!( :load ).and_return( {
                :database => {
                    :user => @user,
                    :password => @password,
                    :catalog => @catalog,
                    :host => @host,
                    :port => @port
                },
            }
        )
        @config = DeploymentConfiguration.new
    end

    it "should use a file named config.yaml, installed at the top level application directory by default" do
        @config.send( :base_uri ).should eql( '~/config.yaml' )
    end

    it 'should return a modified hash object, whose members are also hash-mods unless they are scalar values' do
        [ @user, @password, @host, @port ].each do |item|
            properties = @config.database
            hash_key = item.to_sym
            properties.respond_to?( hash_key ).should be_true
            properties.send( hash_key ).should eql( item )
            properties.should_not respond_to( :foo_bar )
        end
    end

    it 'should return a set of usable parameters for a database connection (if specified correctly)' do
        [ @host, @port, @catalog, @user, @password ].should eql( @config.connection_parameters )
    end

    it 'should not error when asked for a connection string' do
        #todo: make this a value based assertion
        lambda do
            @config.respond_to?( :connection_string ).should be_true
        end.should_not raise_error
    end

end

describe given( ETL::DeploymentConfiguration ), 'when unable to load a configuration file' do

    it 'should explode accordingly!' do
        YAML.stub!( :load ).and_raise( StandardError )
        DeploymentConfiguration.class_eval { @@instance = nil }
        DeploymentConfiguration.class_eval { @@instance }.should be_nil
        lambda do
            config = DeploymentConfiguration.new
            config.respond_to? :database
        end.should raise_error( InvalidOperationException )
    end

end
