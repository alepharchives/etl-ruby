#!/usr/bin/env ruby

require 'rubygems'
require "spec"
require File.dirname(__FILE__) + "/../../spec_helper"
require 'log4r'

include BehaviourSupport

class KernelInstanceExecTestSpy
    def initialize(expectations)
        @stored_expectations = expectations
    end
    def test(expectations, &block)
        instance_exec(expectations, &block)
    end
end

describe "Class initialization extension methods" do

    it "should execute a supplied block in the context of the containing instance" do
        expectations = {
            :name => :test_spy,
            :age => 21,
            :dob => '09-09-1965'
        }
        match = false
        test_spy = KernelInstanceExecTestSpy.new(expectations)
        test_spy.test(expectations.dup) do |expectation_hash|
            @stored_expectations.each do |key, value|
                match = true if expectation_hash[key].eql?(value)
            end
        end
        match.should be_true
    end

    it "should log to a global $logger unless a sender is specified" do
        Log4r::Logger.should_receive(:[]).with("default").and_return(dummy)
        _debug("message", exception=nil, sender=nil)
    end

    it "should write the message directory to the logger" do
        mock_logger = dummy
        Log4r::Logger.stub!(:[]).and_return(mock_logger)
        log_message = "foo"
        mock_logger.should_receive(:debug).once #.with(log_message)

        _debug(log_message)
    end

    it "should also write the exception object's backtrace if present" do
        message = "foo"
        backtrace = "backtrace"
        exception = dummy
        exception.stub!(:backtrace).and_return(backtrace)
        mock_logger = dummy
        Log4r::Logger.stub!(:[]).and_return(mock_logger)
        mock_logger.should_receive(:debug).twice #.with(message)
        #mock_logger.should_receive(:debug).with(backtrace)

        _debug(message, exception)
    end

    it "should perform a direct assignment for all local variables, to fields of the same name" do
        class AssignmentTestClass
            attr_accessor :name, :dob, :rank
            def initialize(name, dob, rank)
                auto_assign_locals(binding())
            end
            def eql?(other)
                instance_variables.each do |varname|
                    unless varname.eql?('@__binding_context')
                        return false unless instance_variable_get(varname).eql?(
                            other.send(:instance_variable_get, varname))
                    end
                end
                return true
            end
        end

        name = "Test"
        dob = Time.now()
        rank = :trainee
        subject = AssignmentTestClass.new(name, dob, rank)

        expected = AssignmentTestClass.new(nil,nil,nil)
        expected.name = name
        expected.dob = dob
        expected.rank = rank

        subject.should eql(expected)
    end
    
    it "should only assign the named local variables" do
        class SelectiveAssignmentTestClass
            attr_accessor :price, :product_line, :promotion_code
            def initialize(price, product_line, promotion_code)
                auto_assign(binding(), :price, :product_line) #NB: promotion code is lost!
            end
            def eql?(other)
                instance_variables.each do |varname|
                    unless varname.eql?('@__binding_context')
                        return false unless instance_variable_get(varname).eql?(
                            other.send(:instance_variable_get, varname))
                    end 
                end
            end
        end
        
        price = 10.25
        product_line = :PerfumesAndScentChemicalsOfNaturalOrigin
        promotion_code = :N16TF7
        
        subject = SelectiveAssignmentTestClass.new(price, product_line, promotion_code)
        
        expected = SelectiveAssignmentTestClass.new(nil,nil,nil)
        expected.price = price
        expected.product_line = product_line
        
        subject.should eql(expected)
    end

end
