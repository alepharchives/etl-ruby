#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'

include BehaviourSupport

#####################################################################################
##############                      Test Support                    #################
#####################################################################################

#REFACTOR: make this useful or inline class

module CommandSpecBehaviourSupport
    def instantiate_command( *options )
        return @command_class.new if options.nil?
        return @command_class.send( :new, *options )
    end
end
