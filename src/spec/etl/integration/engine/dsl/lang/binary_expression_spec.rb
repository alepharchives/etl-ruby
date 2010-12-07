#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::DSL::Lang::BinaryExpression ) do

    it "should explode if the lvalue is nil" do
	lambda {
	    BinaryExpression.new(nil, nil, nil)
        }.should raise_error(ArgumentError, "the 'lvalue' argument cannot be nil")
    end

    it "should explode if the rvalue is nil" do
	lambda {
	    BinaryExpression.new(dummy, nil, nil)
        }.should raise_error(ArgumentError, "the 'rvalue' argument cannot be nil")
    end

    it "should explode if the operator is nil" do
	lambda {
	    BinaryExpression.new(dummy, dummy, nil)
        }.should raise_error(ArgumentError, "the 'operator' argument cannot be nil")
    end    
    
    it "should evaluate the lvalue expression" do
	lvalue, rvalue, operator = dummy, dummy, :>
	expression = BinaryExpression.new(lvalue, rvalue, operator)
	
	lvalue.should_receive(:evaluate).once.with(exchange=dummy).and_return(lvalue)
	expression.evaluate(exchange)
    end
    
    it "should send the operator as a message to the result of lvalue evalutation" do
	lvalue, rvalue, operator = dummy, dummy, :&
	expression = BinaryExpression.new(lvalue, rvalue, operator)
	
	mock_lvalue_response = mock 'response'
	lvalue.stub!(:evaluate).and_return(mock_lvalue_response)
	
	mock_lvalue_response.should_receive(:send).once.with(operator, anything)
	expression.evaluate(dummy)
    end
    
    it "should evalute the rvalue before passing the response to the result of evaluating the lvalue" do
	lvalue, rvalue, operator = dummy, dummy, :&
	expression = BinaryExpression.new(lvalue, rvalue, operator)
	
	mock_lvalue_response = mock 'response'
	dummy_rvalue_response = dummy
	rvalue.stub!(:respond_to?).and_return(:true)
	lvalue.stub!(:evaluate).and_return(mock_lvalue_response)
	rvalue.stub!(:evaluate).and_return(dummy_rvalue_response)
	
	mock_lvalue_response.should_receive(:send).once.with(operator, dummy_rvalue_response).and_return(false)
	expression.evaluate(dummy).should be_false	
    end
    
    it "should pass the rvalue verbatim unless it responds to the 'evaluate' message" do
	greater_than = :>
	lvalue, rvalue, operator = dummy, 30, greater_than
	expression = BinaryExpression.new(lvalue, rvalue, operator)
	
	mock_lvalue_response = 26
	lvalue.stub!(:evaluate).and_return(mock_lvalue_response)
	
	expression.evaluate(dummy).should eql(26 > 30)
    end
    
end
