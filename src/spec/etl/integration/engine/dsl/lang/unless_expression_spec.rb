#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given(ETL::Integration::Engine::DSL::Lang::UnlessExpression) do
    
    it "should explode if the underlying expression is nil" do
	lambda {
	    UnlessExpression.new(nil)
        }.should raise_error(ArgumentError, "the 'underlying expression' argument cannot be nil")
    end
    
    it "should test against the result of the underlying expression" do
	underlying_expression = mock 'expression'
	expression = UnlessExpression.new(underlying_expression)
	dummy_exchange = dummy
	
	underlying_expression.should_receive(:evaluate).once.with(dummy_exchange)
	expression.evaluate(dummy_exchange)
    end
    
    it "should apply ruby's normal (c-style) truth/falsehood semantics to nil values" do
	underlying_expression = Expression.new { nil }
	expression = UnlessExpression.new(underlying_expression)
	expression.evaluate(dummy).should be_true
    end

    it "should apply ruby's normal (c-style) truth falsehood semantics to non-nil values" do
	underlying_expression = Expression.new { Object.new }
	expression = UnlessExpression.new(underlying_expression)
	expression.evaluate(dummy).should be_false
    end
    
    it "should respond to synonyms for the two binary operators it supports" do
	expression = UnlessExpression.new(dummy)
	expression.should respond_to(:and)
	expression.should respond_to(:or)
    end    

end
