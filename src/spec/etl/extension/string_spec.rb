#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'
include BehaviourSupport

include ETL

describe String do
    
    it "should silently respond to 'evaluate' and return self" do
        instance = "foo"
        instance.evaluate(dummy).should equal(instance)
    end
    
    it "should correctly return the last element in a string" do
        "foobarbaz".last.should eql('z')
    end
    
    it "should determine when a string starts with a specific substring" do
        "foobar".starts_with?('foo').should be_true
    end
    
    it "should determine when a string does not start with a specific substring" do
        "barbaz".starts_with?('baz').should be_false
    end
    
    it "should determine when a string ends with a specific substring" do
        "buspass".ends_with?('pass').should be_true
    end
    
    it "should determine when a string does not end with a specific substring" do
        "foobar".ends_with?('baz').should be_false
    end
    
    it "should camelize a string on demand" do
        "foo_bar_baz".camelize.should eql("FooBarBaz")
    end
    
    it "should do a 'lower case starting letter' version of camelize on demand" do
        "foo_bar_baz".camelize(:lower).should eql("fooBarBaz")
    end
    
    it "should properly determine when a string is nil or empty" do
        [ nil, "" ].each { |string| String.nil_or_empty?(string).should be_true }
    end
    
end
