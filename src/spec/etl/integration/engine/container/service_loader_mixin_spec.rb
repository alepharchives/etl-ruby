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

describe given(ETL::Integration::Engine::Container::ServiceLoaderMixin) do

    include ETL::Integration::Engine::Container::ServiceLoaderMixin

    before :each do
        @context = duck
    end

    def context()
        return @context
    end

    it "should use the execution integration environment support methods to load the script resource" do
        filename = "filename"
        self.should_receive(:load_script_resource).once.with(filename).and_return("source code...")
        precompiler = duck
        ServicePrecompiler.stub!(:new).and_return(precompiler)
        modified_source = "modified source code..."
        precompiler.stub!(:get_modified_source_code).and_return(modified_source)
        class_builder = dummy("class builder test spy")
        self.stub!(:define_class).and_return(class_builder)
        class_builder.should_receive(:add_method_def).with('configure', modified_source)
        load(filename)
    end

    it "should precompile the source code and pass it to the class builder" do
        #TODO: this is a really ugly hack of a test -> we should split it in two, at least.
        self.stub!(:load_script_resource).and_return("source code...")
        precompiler = duck
        ServicePrecompiler.stub!(:new).and_return(precompiler)
        modified_source = "modified source code..."
        precompiler.stub!(:get_modified_source_code).and_return(modified_source)
        class_builder = dummy("class builder test spy")
        self.stub!(:define_class).and_return(class_builder)
        class_builder.should_receive(:add_method_def).with('configure', modified_source)
        load("file name is ignored...")
    end

    it "should call build on the builder returned by the class builder's #compile method" do
        self.stub!(:load_script_resource).and_return("source code...")
        precompiler = duck
        ServicePrecompiler.stub!(:new).and_return(precompiler)
        modified_source = "modified source code..."
        precompiler.stub!(:get_modified_source_code).and_return(modified_source)
        class_builder = dummy
        self.stub!(:define_class).and_return(class_builder)
        builder = mock("builder test spy")
        class_builder.stub!(:compile).and_return(builder)
        builder.should_receive(:build).once.with(@context)
        load("file name is ignored...")
    end

    it "should resolve a relative path starting with '.' to an internal relative path (i.e. one prepended to the bootstrap_file's path)" do
        path = "foo/bar/baz"
        @context.stub!(:bootstrap_file).and_return("#{path}/boot.service")
        self.should_receive(:load_script_resource).once.with("#{path}/child-service")
        precompiler = duck
        ServicePrecompiler.stub!(:new).and_return(precompiler)
        modified_source = "modified source code..."
        precompiler.stub!(:get_modified_source_code).and_return(modified_source)
        class_builder = dummy("class builder test spy")
        self.stub!(:define_class).and_return(class_builder)
        class_builder.should_receive(:add_method_def).with('configure', modified_source)
        load("./child-service")
    end

end
