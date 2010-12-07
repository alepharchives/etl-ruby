#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path( File.dirname( __FILE__ ) + '/spec_helper' )
require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'

include FileUtils
include BehaviourSupport
include MIS::Framework

#####################################################################################
##############                      Test Support                    #################
#####################################################################################

describe "All File System Migration Commands", :shared => true do

    include CommandSpecBehaviourSupport

    before :each do
        raise InvalidOperationException, "Must define a command class in your spec!", caller unless @command_class
        raise InvalidOperationException, "Must define a command symbol in your spec!", caller unless @command_symbol
        @landing = '/opt/mis/landing_point/'
    end

    it 'should handle individual files appropriately' do
        source = @landing + 'session.server.log.2007-06-06'
        target_directory = '/opt/mis/archive/'
        File.should_receive( :file? ).twice { |uri| uri.include? source }
        File.should_receive( :directory? ) { |uri| uri.include? target_directory }
        setup_expectations_and_migrate source, target_directory
    end

    it "should handle whole directories appropriately, copying both content and structure" do
        source = @landing + 'session_data/'
        target_directory = '/opt/mis/archive/session'
        define_both_uris_as_directory source, target_directory
        setup_expectations_and_migrate source, target_directory
    end

    it 'should handle directory contents (minus structure) accord to the supplied options' do
        source = @landing + 'session_data'
        target_directory = '/opt/mis/archive/session'
        define_both_uris_as_directory source, target_directory
        command = @command_class.new source, target_directory, :content_only => true
        command.should_receive( @command_symbol ).once.with( source + '/.', target_directory, :verbose => true )
        command.execute
    end

    it 'should process a glob list on a per-uri basis' do

        #REFACTOR: this will break any future tests that expect verification of the destination as a directory.

        source = [ 1, 2, 3 ].collect { |number| "file#{number}.txt" }
        target_directory = '/opt/mis/archive/session'
        File.should_receive( :file? ).exactly( 3 ).times.and_return { |uri| uri == 'file3.txt' ? false : true }
        lambda do
            command = @command_class.new( source, target_directory )
        end.should raise_error( ArgumentError, "Uri file3.txt does not map to a file or directory." )
    end

    it 'should wrap any underlying errors for the caller' do
        src = 'sourcefile.txt'
        target_directory = '/opt/mis/landing_point'
        File.stub!( :file? ).and_return true
        command = @command_class.new src, target_directory
        command.should_receive( @command_symbol ).with( any_args ).and_raise( IOError )
        lambda do
            command.execute
        end.should raise_error( ProcessingError, $! )
    end

    def define_both_uris_as_directory source, target_directory
        File.should_receive( :file? ).once.with( source ).and_return( false )
        File.should_receive( :directory? ).once.with( source ).and_return( true )
        File.should_receive( :file? ).once.with( target_directory ).and_return( false )
        File.should_receive( :directory? ).once.with( target_directory ).and_return( true )
    end

    def setup_expectations_and_migrate source, target_directory, options={}
        command = @command_class.new source, target_directory, options
        command.should_receive( @command_symbol ).with( source, target_directory, :verbose => true )
        command.execute
    end

end
