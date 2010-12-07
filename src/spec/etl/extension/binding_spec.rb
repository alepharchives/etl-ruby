#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'
include BehaviourSupport

include ETL

#todo: finish these tests off

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

module BindingClassTestSupport

    def test_binding_context( context )
        yield context
    end

end

class Example
    Name = 'example'
    def initialize
        @name = Name
    end

    def get_context
        binding
    end
end

describe "Ruby Core Binding Class Extensions", 'when used to create a binding object' do

    include BindingClassTestSupport

    it "should provide a means for accessing a binding context's local variable names" do
        foo = 'foo'
        bar = 'bar'
        locals = local_variables
        test_binding_context( binding ) { |context|
            context.local_variables.should eql( ( [ 'locals' ] << locals ).flatten )
        }
    end

    it "should correctly support queries for things that are bound verses things that aren't" do
        bound = 'bound variable'
        ctx = binding()
        test_binding_context( binding() ) { |context|
            context.def?( 'bound' ).should be_true
            context.def?( 'unbound' ).should be_false
        }
    end

    it 'should support the notion of scope accessor(s) for all local variables' do
        me = 'tester'
        you = 'reader'
        test_binding_context( binding() ) { |context|
            context.me.should eql( me )
            context.you.should eql( you )
        }
    end

    it 'should evaluate the supplied block in the context of the caller' do
        foo = 'foo'
        test_binding_eval( binding )
    end

    def test_binding_eval( context )
        context.evaluate "foo.should eql( 'foo' )"
    end

end

describe "Ruby Core Binding Class Extensions", 'when used to execute code in a specific context' do

    include BindingClassTestSupport

    it 'should correctly resolve any local variables' do
        binding_context = get_context_with_two_locals( 'foo', 'bar' )
        first, second = nil, nil
        binding_context.scope_eval do
            first = local1
            second = local2
        end
        first.should eql( 'foo' )
        second.should eql( 'bar' )
    end

    it 'should pass in a context instance for getting at field names' do
        context = Example.new.get_context
        name = nil
        context.scope_eval do |this|
            name = this.instance_variable_get( '@name' )
        end
        name.should eql( 'example' )
    end

    def get_context_with_two_locals( local1, local2 )
        binding()
    end

end