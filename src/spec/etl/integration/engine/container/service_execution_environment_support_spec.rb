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

describe given(ETL::Integration::Engine::Container::ServiceExecutionEnvironmentSupport) do

    include ServiceExecutionEnvironmentSupport

    it "should create a ClassDef instance when you send the 'define_class' message" do
        define_class("ClassNamedFoo").should be_an_instance_of(ServiceExecutionEnvironmentSupport::ClassDef)
    end

    it "should set the class name and ancestors on the ClassDef instance" do
        name = "MyClass"
        ancestry = ServiceConfigurationBuilder
        expected_def = ServiceExecutionEnvironmentSupport::ClassDef.new
        expected_def.class_name = name
        expected_def.class_ancestors = ancestry
        classDef = define_class(name, ancestry)
        classDef.should eql(expected_def)
    end

    it "should store the supplied MethodDef on the current class def when add_method_def is called" do
        classDef = define_class("MyClass")
        method_name = "foo"
        source_code = "return 'foo'"
        classDef.add_method_def(method_name, source_code)
        expected_method_def = ServiceExecutionEnvironmentSupport::MethodDef.new
        expected_method_def.method_name = method_name
        expected_method_def.source_code = source_code
        classDef.method_defs.first.should eql(expected_method_def)
    end

    it "should return a subclass of ServiceConfigurationBuilder" do
        clazz = define_class("CustomBuilder", ServiceConfigurationBuilder)
        product = clazz.compile()
        product.should be_a_kind_of(ServiceConfigurationBuilder)
    end

    it "should add the supplied method(s) to the generated class" do
        clazz = define_class("CustomBuilder", ServiceConfigurationBuilder)
        clazz.add_method_def("configure", "return 'foo'")
        product = clazz.compile()
        product.send(:configure).should eql('foo')
    end
    
    it "should explode if you try and load an empty string" do
        fileuri = "fileuri"
        data = ""
        File.stub!(:exist?).and_return(true)
        File.should_receive(:read).once.with(fileuri).and_return(data)
        lambda {
            load_script_resource(fileuri)
        }.should raise_error(ClassLoadException)
    end

    it "should return the string unaltered if it is not tainted" do
        source_code = "puts 'hello world!'"
        File.stub!(:read).and_return(source_code)
        load_script_resource("ignored_fileuri.rb").should eql(source_code)
    end
    
    it "should try appending .service and .rb to a filename without an extension" do
        filename1 = "myservice.service"
        filename2 = "myservice.service.rb"
        File.stub!(:read).and_return('foo bar....')
        File.should_receive(:exist?).once.with("myservice").and_return(false)
        File.should_receive(:exist?).once.with(filename1).and_return(false)
        File.should_receive(:exist?).once.with(filename2).and_return(true)
        load_script_resource("myservice")
    end    
    
end

describe given(ETL::Integration::Engine::Container::ServiceExecutionEnvironmentSupport::ModuleDefinitionLoader) do
    
    it "should set a constant on the current class which corresponds to the supplied module name" do
        class TestSubject
            include ServiceExecutionEnvironmentSupport::ModuleDefinitionLoader
            
            def create_dynamic_module()
                dynamic_module_define(:MyModule)
            end
            
            def get_new_const()
                return MyModule
            end
        end
        instance = TestSubject.new
        instance.class.constants.should be_empty
        
        instance.create_dynamic_module()
        
        instance.get_new_const().should eql(TestSubject::MyModule)
    end
    
    it "should evaluate the supplied code block in the context of the specified module and generate the method definitions appropriately" do
        class TestContainerClass
            include ServiceExecutionEnvironmentSupport::ModuleDefinitionLoader
        end
        instance = TestContainerClass.new
        instance.instance_eval do
            dynamic_module_define(:Happy) do
                def talk()
                    return 'I am happy!'
                end
            end
        end
        instance.extend(TestContainerClass::Happy)
        instance.talk().should eql('I am happy!')
    end
    
    it "should set a constant on the current class which corresponds to the supplied class name" do
        class SuperClass
            def talk()
                return "talking..."
            end
        end
        class TestSubject
            include ServiceExecutionEnvironmentSupport::ModuleDefinitionLoader
            
            def create_dynamic_class()
                dynamic_class_define(:MyClass, SuperClass) do
                    def talk()
                        return "#{self.class} is " + super()
                    end
                end
            end
            
            def get_result()
                return TestSubject::MyClass.new.talk()
            end            
        end
        instance = TestSubject.new
        instance.create_dynamic_class()
        
        instance.get_result().should eql("TestSubject::MyClass is talking...")
    end
    
end
