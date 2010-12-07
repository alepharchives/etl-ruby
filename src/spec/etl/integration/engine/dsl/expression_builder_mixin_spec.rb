#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

class SpecRunner
    include ExpressionBuilderMixin
    def run(&block)
        return instance_eval(&block)
    end
end

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ETL::Integration::Engine::DSL::ExpressionBuilderMixin) do

    before :each do
        @testRunner = SpecRunner.new
    end
    
    it "should return a HeaderExpression for the given name" do
        expression = @testRunner.run() { header(:basename) }
        expression.header_name.should eql(:basename)
    end
    
    it "should silently turn method_missing into a header expression" do
        [ :scheme, :uri, :path ].each do |headername|
            @testRunner.send(headername).should be_an_instance_of(HeaderExpression)
        end
    end
    
    it "should return a 'truth' expression for 'always'" do
        exchange = duck
        @testRunner.run() do
            always().evaluate(exchange)
        end.should be_true
    end
    
    it "should return a 'falsehood' expression for 'never'" do
        exchange = duck
        @testRunner.run() do
            never.evaluate(exchange)
        end.should be_false
    end
    
    it "should explode if a 'negate' method is called passing an object that doesn't respond to 'evaluate'" do
        badExpression = dummy
        lambda {
            @testRunner.run() { negate(badExpression) }
        }.should raise_error(InvalidExpressionException)
    end

    it "should return an expression that 'negates' the underlying expression when evaluated" do
        ignored = dummy
        [ true, false ].each do |value|
            underlyingExpression = Expression.new { value }
            @testRunner.run() do
                negate(underlyingExpression).evaluate(ignored)
            end.should_not send("be_#{value}".to_sym)
        end
    end
    
    it "should validate the expression supplied to 'where' and return it unaltered" do
        expression = dummy
        expression.should_receive(:respond_to?).once.with(:evaluate).and_return(true)
        @testRunner.run() do
            where(expression)
        end.should eql(expression)
    end

    
    it "should return an expression that consumes the 'body' property of an inbound message (exchange)" do
        exchange = Exchange.new(dummy)
        message = Message.new
        message.should_receive(:body).once.and_return('foo bar baz')
        exchange.inbound = message
        
        expression = @testRunner.run() { body() }
        expression.evaluate(exchange)
    end
    
    #TODO: does this test really belong here!?
    it "should correctly resolve an evaluated binary expression" do
        @testRunner.run() do
            where(scheme.equals('file') & header(:basename).matches(/\.ldif/i))
        end.should be_an_instance_of(BinaryExpression)
    end
    
end
