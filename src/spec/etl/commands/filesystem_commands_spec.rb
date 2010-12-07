#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/io_commands'
require File.dirname(__FILE__) + '/migrate_command_helper'

include BehaviourSupport
include MIS::Framework

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( CopyCommand ), 'when utilized to migrate data and structure(s) on disk' do

    it_should_behave_like "All I/O Dependant Commands"
    it_should_behave_like "All File System Migration Commands"

    before :all do
        @command_symbol = :cp_r
        @command_class = CopyCommand
    end

end

describe given( MoveCommand ), 'when utilized to migrate data and structure(s) on disk' do

    it_should_behave_like "All I/O Dependant Commands"
    it_should_behave_like "All File System Migration Commands"

    before :all do
        @command_symbol = :mv
        @command_class = MoveCommand
    end

end
