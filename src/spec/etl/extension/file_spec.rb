#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'
include BehaviourSupport

include ETL

#todo: finish these tests off

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe 'A set of File, Path and PathResolver extension methods' do

    before :all do
        @initial_directory = path_from_uri File.dirname( __FILE__ )
        search_for_config_and_reset_initial_dir
        ENV['STARTUP_PATH'] = @initial_directory unless $LOAD_PATH.include? @initial_directory
    end

    it 'should correctly resolve a path relative to the root project directory' do
        #todo: reconsider this project folder structure dependant assertion!
        data_directory = path_from_uri File.resolve_path( '~/test/integration/data' )
        data_directory.directory?.should be_true
    end

    it 'should explode if resolving an incorrectly prefixed path' do
        lambda do
            File.resolve_path 'tst/integration/data'
        end.should raise_error
    end

    def search_for_config_and_reset_initial_dir
        path = @initial_directory.expand
        unless path.join( 'config.yaml' ).exist?
            path.resolve! '..' until path.join( '/config.yaml' ).file?
        end
        @initial_directory = path.dirname
    end

end
