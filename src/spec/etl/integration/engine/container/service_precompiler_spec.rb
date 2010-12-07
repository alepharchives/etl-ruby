#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

#TODO: REFACTOR: These feel more like integration tests than unit tests...?

describe given(ETL::Integration::Engine::Container::ServicePrecompiler) do

    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = ServicePrecompiler
        @constructor_args = [ 'file', 'code' ]
    end

    it "should replace any module definitions with 'dynamic_module_define' messages subseeded by a block" do
        code=<<-CODE
            module SupportModule
                def run()
                    #TODO: implement this...
                end
            end
        CODE

        expected_code=<<-CODE
            dynamic_module_define(:SupportModule) do
                def run()
                    #TODO: implement this...
                end
            end
        CODE
        verify_expectations(code, expected_code)
    end

    it "should replace any class definitions with 'dynamic_class_define' messages subseeded by a block" do
        code=<<-CODE
            include MIS::Engine

            class CustomProcessor < ETL::Integration::Engine::Processors::Processor
                def initialize()
                    super(:name=>'my processor name')
                end
                def do_process(exchange)
                    #todo: implement...
                end
            end

            def custom()
                return CustomProcessor.new()
            end

            pipeline("etl://mypipeline").from("lfs:/" + context().config().dumpdir).to("etl://processing-service").via(custom())
        CODE

        expected_code=<<-CODE
            include MIS::Engine

            dynamic_class_define(:CustomProcessor, ETL::Integration::Engine::Processors::Processor) do
                def initialize()
                    super(:name=>'my processor name')
                end
                def do_process(exchange)
                    #todo: implement...
                end
            end

            def custom()
                return CustomProcessor.new()
            end

            pipeline("etl://mypipeline").from("lfs:/" + context().config().dumpdir).to("etl://processing-service").via(custom())
        CODE
        verify_expectations(code, expected_code)
    end

    it "should not 'grep' out any comments following on from the class def" do
        code=<<-CODE
            class MyClass #:nodoc:
            end
        CODE
        expected_code=<<-CODE
            dynamic_class_define(:MyClass) do #:nodoc:
            end
        CODE
        verify_expectations(code, expected_code)
    end

    it "should not 'grep' out any comments following on from a class def with an ancestor" do
        code=<<-CODE
            class MyClass < MySuperClass #:nodoc:
            end
        CODE
        expected_code=<<-CODE
            dynamic_class_define(:MyClass, MySuperClass) do #:nodoc:
            end
        CODE
        verify_expectations(code, expected_code)
    end

    it "should explode if you supply a class definition with a commented out superclass defined" do
        code=<<-CODE
            class MyClass # < MySuperClass
            end
        CODE
        lambda {
            verify_expectations(code, "")
        }.should raise_error(ServicePrecompiler::PrecompilerError)
    end

    def verify_expectations(code, expected_code)
        precompiler = ServicePrecompiler.new("dummyFileName", code)
        precompiler.precompile()
        precompiler.get_modified_source_code.should eql(expected_code)
    end

end
