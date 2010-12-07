#!/usr/bin/env ruby

=begin

the files in directories below the one in which this file sits, will need to do some work in order
to include it; typically, you'll need to step up by one or more directories before adding the module
name suffix (spec_helper in this case) to your gem, require and/or load statement. Here's an example,
taken from a file that is two directories below this one.

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'

=end

require 'rubygems'
require 'spec'

#####################################################################################
##############                 Load Library                          ################
#####################################################################################
=begin note:

The main work done by this file is here, where we add the path to the root
directory of the actual source code folder structure, to the ruby load path.

There is also a call to set the STARTUP_PATH environment variable, which is
required by the native File class extension module in order to properly
resolve relative paths.

=end

dir = File.dirname(__FILE__)
lib_path = File.expand_path("#{dir}/../lib")
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)

ENV['STARTUP_PATH'] = File.expand_path("#{dir}/../../") unless ENV['STARTUP_PATH']

require 'etl'

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

#test doubles...

class FileDouble #:nodoc:
    attr_reader :data
    def initialize( data=nil )
        @data = data
    end
    def method_missing( name, *args )
        #pass
    end
    def <<(raw_data)
        if @data.nil?
            @data = raw_data
        else
            @data += raw_data
        end
    end

end

class DummyEntry
    attr_accessor :uid, :mail, :cn, :member, :applicationEnabled, :disableReason

    def initialize( uid=nil, main=nil, cn=nil, member=nil, applicationEnabled=nil, disableReason=nil )
        @uid, @main, @cn, @member, @applicationEnabled, @disableReason = uid, main, cn, member, applicationEnabled, disableReason
    end

    def as_delimited_text( delimiter )
        [ uid, mail, cn, member ].join delimiter
    end
end

module BehaviourSupport

    def given( a_descriptor )
        #creates a BDD style 'Given a ...' statement in the specdoc

        #raise Error, 'you need to supply a block my friend!' unless block_given?

        a_descriptor = a_descriptor.name if a_descriptor.kind_of? Class
        desc_text = "An #{a_descriptor}"
    end

    def null_object( name=nil )
        ( @@current_generated_id ||= '1' ).succ!
        return mock( name || "dummy_object#{@@current_generated_id}", :null_object => true )
    end

    alias dummy null_object
    
    def duck( name=nil )
	aduck = dummy( name )
	aduck.stub!(:respond_to?).and_return(true)
	return aduck
    end

    # Stubs Object with the expectation of a call to :connect, once
    # with the supplied host, port, dbname, login and passwd.
    #
    # Yields the stubbed proxy for further expecation setting, and finally,
    # returns a constructed jdbc style postgres connection string, for use as a uri.
    def setup_postgres_connectivity_expectations_on(
            host, port, dbname, login, passwd )
        yield Object.should_receive( :connect ).once.with(
            :host => host,
            :port => port,
            :catalog => dbname,
            :user => login,
            :password => passwd
        )
        return "postgres://#{host}:#{port}/#{dbname}?user=#{login}&password=#{passwd}"
    end
end

describe "All tested constructor behaviour", :shared => true do

    include Validation

    it "should validate all the arguments supplied to it's constructor" do
        validate_instance_variables( binding(), :constructor_args, :clazz ) do |var|
            raise StandardError, "you need to set the #{var} instance variable in your before :all setup method!"
        end
        @constructor_args.each_with_index do |argument_name, index|
            args = []
            (0..@constructor_args.size - 1).each do |argument_index|
                if argument_index >= index
                    args.push( nil )
                else
                    args.push( dummy )
                end
            end
            lambda {
                @clazz.send( :new, *args )
            }.should raise_error(ArgumentError, "the '#{argument_name.gsub( /_/, ' ' )}' argument cannot be nil")
        end
    end

end rescue nil

module SqlBehaviourSupport

    def bulk_loader_with_valid_connectivity
        class_with_valid_connectivity_expectations( SqlBulkLoader )
    end

    def data_extractor_with_valid_connectivity
        class_with_valid_connectivity_expectations( SqlExtractor )
    end

    def class_with_valid_connectivity_expectations( clazz )
        connection_string = setup_postgres_connectivity_expectations_on(
            'localhost', 5432, 'CAT_STAGING', 'sa', 'q0h5l5th' ) do |wrap|
            wrap.and_return( @mock_connection )
        end
        clazz.new connection_string
    end
end
