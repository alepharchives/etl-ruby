#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'
require File.dirname( __FILE__ ) + '/spec_helper'

include BehaviourSupport
include MIS::Framework

#####################################################################################
##############                      Test Support                    #################
#####################################################################################

describe "All I/O Dependant Commands", :shared => true do

    include CommandSpecBehaviourSupport

    before :each do
        raise InvalidOperationException, "Must define a command class in your spec!", caller unless @command_class
    end

    [ :source, :destination ].each do |invalid_argument_name|

        source = 'sourcefile.txt'
        destination = 'destination.txt'

        it "should explode if supplied with an invalid #{invalid_argument_name} argument" do
            options = eval(<<-EOF
                    [
                        #{ invalid_argument_name == :source ? 'nil,' : 'source,' }
                        #{ invalid_argument_name == :destination ? 'nil, ' : 'destination, ' }
                        'Sandbox'
                    ]
                EOF
            )
            lambda do
                instantiate_command( *options )
            end.should raise_error( ArgumentError )
        end

        it "should explode if the supplied #{invalid_argument_name} uri isn't valid" do
            File.stub!( :directory? ).and_return false
            call_count = invalid_argument_name == :source ? 'once' : 'twice'
            eval( <<-CODE
                File.should_receive( :file? ).#{call_count} do |uri|
                    recognized_uri = true
                    recognized_uri = false if invalid_argument_name == :source and uri == source
                    recognized_uri = false if invalid_argument_name == :destination and uri == destination
                    recognized_uri
                end
            CODE
            )

            lambda do
                instantiate_command( source, destination, 'Sandbox' )
            end.should raise_error( ArgumentError, "Uri #{eval invalid_argument_name.to_s} does not map to a file or directory." )
        end

    end

end
