#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given(ETL::Integration::Engine::DSL::Lang::IfExpression) do
    
    it "should explode if the underlying expression is nil" do
	lambda {
	    IfExpression.new(nil)
        }.should raise_error(ArgumentError, "the 'underlying expression' argument cannot be nil")
    end
    
    it "should test against the result of the underlying expression" do
	underlying_expression = Expression.new { true }
	expression = IfExpression.new(underlying_expression)
	expression.evaluate(dummy).should be_true
    end
    
    it "should apply ruby's normal (c-style) truth/falsehood semantics to nil values" do
	underlying_expression = Expression.new { nil }
	expression = IfExpression.new(underlying_expression)
	expression.evaluate(dummy).should be_false
    end

    it "should apply ruby's normal (c-style) truth falsehood semantics to non-nil values" do
	underlying_expression = Expression.new { Object.new }
	expression = IfExpression.new(underlying_expression)
	expression.evaluate(dummy).should be_true
    end

end