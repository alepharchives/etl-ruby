#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given(ETL::Integration::Engine::DSL::Lang::MatchesExpression) do
    
    it "should explode if the match pattern is nil" do
	lambda {
	    MatchesExpression.new(nil, nil)
        }.should raise_error(ArgumentError, "the 'match pattern' argument cannot be nil")
    end
    
    it "should explode if the underlying expression is nil" do
	lambda {
	    MatchesExpression.new(dummy, nil)
        }.should raise_error(ArgumentError, "the 'underlying expression' argument cannot be nil")
    end
    
    it "should silently convert a string into a regex" do
	match_pattern = "([\w]+)(?=\.dump)"
	Regexp.should_receive(:compile).once.with(match_pattern).and_return(dummy)
	MatchesExpression.new(match_pattern, dummy)
    end
    
    it "should wrap a regex compilation error in an appropriate exception" do
	Regexp.should_receive(:compile).once.with(dummy_match_pattern=dummy).and_raise(RegexpError)
	lambda {
	    MatchesExpression.new(dummy_match_pattern, dummy)
        }.should raise_error(ArgumentError, "Unable to compile regexp match pattern '#{dummy_match_pattern}'")
    end
    
    it "should use the regex to match against the value returned by the underlying exchange" do
	test_data = "chunky bacon, oh yeah!"
	match_pattern = /chunky bacon/
	underlying_expression = mock 'expression test stub'
	underlying_expression.stub!(:evaluate).and_return(test_data)
	
	expected_result = 'chunky bacon'
	expression = MatchesExpression.new(match_pattern, underlying_expression)
	expression.evaluate(dummy).should eql(expected_result)
    end
    
    it "should explode if the underlying exchange returns a value that does not support regex match syntax" do
	invalid_response = mock 'response test stub'
	underlying_expression = mock 'expression test stub...'
	underlying_expression.stub!(:evaluate).and_return(invalid_response)
	invalid_response.stub!(:respond_to?).and_return(false)
	
	expression = MatchesExpression.new(/pattern is ignored/, underlying_expression)
	lambda {
	    expression.evaluate(dummy)
        }.should raise_error(InvalidExpressionException)
    end
    
end
