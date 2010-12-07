#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

class FalseExpression < Expression
    conversion_to :if
    def evaluate(exchange)
	return false
    end
end

class NumExpression < Expression
    binary_operator :-
    conversion_to :equals
    def initialize(value)
	super() { value }
    end
end
	
#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::DSL::Lang::Expression ) do

    it "should explode if you try to evaluate it without supplying a block to the constructor" do
	expression = Expression.new
	lambda {
	    expression.evaluate(dummy)
        }.should raise_error(NoMethodError)
    end
    
    it "should use the block to evaluate if one is supplied" do
	expression = Expression.new { false }
	expression.evaluate(dummy).should be_false
    end
    
    it "should define a method on subclasses for each supplied binary_operator" do
	class AndExpression < Expression
	    binary_operator :&
        end
	expression = AndExpression.new
	expression.should respond_to(:&)
    end
    
    it "should resolve a binary_operator defined method into an instance of BinaryExpression" do
	class TestExpression < Expression
	    binary_operator :%
        end	
	lhs = TestExpression.new
	rhs = TestExpression.new
	(lhs % rhs).should be_an_instance_of(BinaryExpression)
    end
    
    it "should evaluate against a binary_operator using the correct parse order" do
	lhs = NumExpression.new( 10 )
	rhs = NumExpression.new( 3 )
	expected_result = 7
	expression = lhs - rhs
	expression.evaluate(dummy).should eql(expected_result)
    end
    
    it "should define a method on subclasses for each supplied conversion_to expression" do
	expression = FalseExpression.new
	expression.should respond_to?(:if)
    end
    
    it "should resolve a conversion_to defined message into an appropriate expression type" do
	expression = FalseExpression.new
	expression.if().should be_an_instance_of(IfExpression)
    end
    
    it "should pass itself into the result of a conversion_to message" do
	expression = NumExpression.new( 10 )
	expression.equals(10).evaluate(dummy).should be_true
    end
    
    it "should resolve a call to 'send_method' into another Expression" do
        Expression.new {}.send_method(:foo).should be_an_instance_of(Expression)
    end
    
    it "should forward the message supplied to 'send_method' when evaluating the exchange" do
        response = dummy
        mock_result = dummy
        mock_result.should_receive(:method1).once.with(:foo).and_return(response)
        expression = Expression.new { mock_result }
        
        subject = expression.send_method(:method1, :foo)
        subject.evaluate(dummy)
    end
    
end
