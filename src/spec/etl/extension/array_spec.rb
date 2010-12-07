#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'
include BehaviourSupport

include ETL

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe Array do

    it "should return the second element in the array" do
        [ 1, 2 ].second.should eql(2)
    end
    
    it "should return nil if the array contains less than two elements" do
        [ 1 ].second.should be_nil
    end
    
end
