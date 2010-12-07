#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given(ETL::Integration::Engine::DSL::Lang::HeaderExpression) do
    
    it "should explode if the header name is nil" do
	lambda {
	    HeaderExpression.new(nil)
        }.should raise_error(ArgumentError, "the 'header name' argument cannot be nil")
    end
    
    it "should pull the named header out of the inbound channel of the exchange" do
	expected_value = "test1234"
	mock_exchange = prepared_exchange(expected_value)

	expression = HeaderExpression.new(:basename)
	expression.evaluate(mock_exchange).should eql(expected_value)
    end
    
    it "should explode if there is no such header name" do
	#TODO: revisit this, because nobody else is throwing exceptions like this and I think it's bad...
	expected_value = "test1234"
	mock_exchange = prepared_exchange(expected_value)

	expression = HeaderExpression.new(:no_such_header)
	lambda {
	    expression.evaluate(mock_exchange)
        }.should raise_error(InvalidExpressionException)
    end
    
    [ :equals, :matches, :if, :unless ].each do |message|
	it "should respond to the silent conversion to '#{message}' expression message" do
	    HeaderExpression.new(:ignored).should respond_to(message) 
        end	
    end
    
    it "should explode if you try and pass args to 'if'" do
	expect_argument_error lambda {
	    HeaderExpression.new(:ignored).if('foo bar baz', 29)
        }
    end
    
    it "should explode if you try and pass args to 'unless'" do
	expect_argument_error lambda {
	    HeaderExpression.new(:ignored).unless('foo bar baz', 31)
        }
    end
    
    it "should explode if you try and pass too many args to 'equals'" do
	expect_argument_error lambda {
	    HeaderExpression.new(:ignored).equals(1, 2, 3)
        }
    end
    
    it "should explode if you try and pass too few args to 'equals'" do
	expect_argument_error lambda {
	    HeaderExpression.new(:ignored).equals()
        }
    end

    it "should explode if you try and pass too many args to 'matches'" do
	expect_argument_error lambda {
	    HeaderExpression.new(:ignored).matches('foobar', 'flobby')
        }
    end
    
    it "should explode if you try and pass too few args to 'matches'" do
	expect_argument_error lambda {
	    HeaderExpression.new(:ignored).matches()
        }
    end    
    
    def expect_argument_error(func)
	func.should raise_error(ArgumentError)
    end
    
    def prepared_exchange(expected_value)
	mock_inbound = mock 'inbound message test stub'
	mock_exchange = mock 'exchange test stub'
	mock_exchange.stub!(:inbound).and_return(mock_inbound)
	expected_value = "test1234"
	mock_inbound.stub!(:headers).and_return :basename => expected_value
	return mock_exchange
    end
    
end
