#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'
include BehaviourSupport

include ETL

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

class ValidationTester
    include Validation

    def initialize( arg1, arg2 )
        validate_arguments( binding() )
    end

end

class ObjectValidationTestClass
    mixin Validation

    def initialize( kwargs )
        kwargs.each { |key, value|
            self.instance_variable_set( "@#{key}", value )
        }
    end
    def test_for( *names, &block )
        validate_instance_variables( binding(), *names, &block )
    end
end

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( Validation ), 'when included in a class for validation purposes' do

    include Validation

    it 'should support a coalesce model to convert nil values to a supplied string' do
        foo = nil
        null_string = 'NULL'
        coalesce( foo, null_string ).should eql( null_string )
    end

    it 'should support coalesce model to convert nil or empty values to a supplied string' do
        foo = nil
        bar = ''
        null_string = 'NULL'
        nil_test = coalesce_empty( foo, null_string )
        empty_test = coalesce_empty( bar, null_string )
        nil_test.should eql( empty_test )
        empty_test.should eql( null_string )
    end

    it 'should validate the local variables/method-args on demand' do
        proc { foo = ValidationTester.new( nil, 'bar' ) }.should raise_error( ArgumentError, "the 'arg1' argument cannot be nil" )
    end

    it 'should support validating only named locals' do
        foo, bar, baz = 'foo', 'bar', 'baz'
        local_variables.each do |var|   #foo, bar, baz
            lambda { validate_arguments binding(), var }.should_not raise_error
        end
    end

    it 'should validate the presence of instance variables on demand' do
        subject = ObjectValidationTestClass.new( :application_test => nil )
        lambda {
            subject.test_for( :application_test )
        }.should raise_error( InvalidOperationException, "'application test' not set" )
    end

    it 'should validate the presence of instance variables, using the supplied error handling block' do
        subject = ObjectValidationTestClass.new( :foo => 'foo', :bar => 'bar' )
        lambda {
            subject.test_for( :foo, :bar, :baz ) do |var|
                raise StandardError, "my '#{var}' field wasn't set => D'oh!"
            end
        }.should raise_error( StandardError, "my 'baz' field wasn't set => D'oh!" )
    end

end
