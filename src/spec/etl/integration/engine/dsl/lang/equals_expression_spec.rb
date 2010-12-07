#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given(ETL::Integration::Engine::DSL::Lang::EqualsExpression) do
    
    it "should test against the result of the superclass 'evaluate' call" do
	underlying_expression = Expression.new { nil }
	is_expression = EqualsExpression.new(nil, underlying_expression)
	is_expression.evaluate(dummy).should be_true
    end
    
    it "should test the result of the superclass 'evaluate' call using the eql? method" do
	test_input = dummy
	mock_result = dummy
	underlying_expression = Expression.new { mock_result }
	
	mock_result.should_receive(:eql?).once.with(test_input).and_return(mock_result)
	expression = EqualsExpression.new(test_input, underlying_expression)
	expression.evaluate(dummy).should equal(mock_result)
    end
    
    it "should respond to synonyms for the two binary operators it supports" do
	expression = EqualsExpression.new(dummy, Expression.new)
	expression.should respond_to(:and)
	expression.should respond_to(:or)
    end
    
end
