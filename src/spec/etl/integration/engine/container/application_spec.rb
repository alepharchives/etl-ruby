# #!/usr/bin/env ruby

require 'rubygems'
require 'spec'
require "yaml"

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Framework

# #####################################################################################
# ############## Behaviour Examples                                     ################ #
#####################################################################################

describe given(ETL::Integration::Engine::Container::Application), "when starting a new application" do

    before :each do
        File.stub!(:file?).and_return(true)
        File.stub!(:open).and_return(duck)
        @bootstrap_file = 'myfile'
        @landing = '/media/sdb1/retro_landing'
        @timeout = 10
        config = {
            :bootstrap_file => @bootstrap_file,
            :landing_dir => @landing,
            :watch_sleep_timeout => @timeout,
            :entry_point => "etl://myapplication"
        }
        make_hash_callable(config)
        YAML.stub!(:load).and_return(config)
        @execution_context_stub = dummy
        @execution_context_stub.stub!(:config).and_return(config)
        ExecutionContext.stub!(:new).and_return(@execution_context_stub)
    end

    it "should bootstrap the initial file before running the file watcher" do
        FileWatcher.stub!(:new).and_return(dummy)
        instance = Application.new()
        instance.should_receive(:load).once.with(@bootstrap_file)
        instance.start()
    end
    
    it "should use the supplied expression as a bootstrap in place of a file name if it is supplied" do
        FileWatcher.stub!(:new).and_return(dummy)
        instance = Application.new()
        command_text = 'listener("etl://mypipeline)'
        mock_processor = duck
        instance.stub!(:bootstrap)
        instance.stub!(:load_service).and_return(mock_processor)
        mock_processor.should_receive(:marshal).once.with(any_args())
        instance.start(command_text)
    end

    it "should create a new file watcher using the configured landing directory and watch sleep time settings" do
        FileWatcher.should_receive(:new).once.with(@landing, @timeout).and_return(dummy)
        instance = Application.new()
        instance.stub!(:bootstrap)
        instance.start()
    end

    it "should explode unless an entry point can be resolved after bootstrapping" do
        @execution_context_stub.stub!(:lookup_uri).and_raise(ServiceNotFoundException.new(
            duck, duck, duck))
        instance = Application.new()
        instance.stub!(:bootstrap)
        lambda {
            instance.start()
        }.should raise_error(ServiceNotFoundException)
    end
    
    it "should compile and run the given application on demand, not using the file system watcher component" do
        FileWatcher.should_not_receive(:new)
        instance = Application.new()
        instance.stub!(:bootstrap)
        instance.stub!(:bootstrap_code).and_return(duck)
        instance.should_receive(:run)
        instance.start("execute('etl://mypipeline')")
    end
    
    it "should explode if the expression does not evaluate to a suitable endpoint" do
        application = Application.new()
        application.stub!(:bootstrap)
        application.stub!(:bootstrap_code).and_return(mock("exploding response..."))
        lambda {
            application.start("foo bar baz")
        }.should raise_error(ClassLoadException)
    end

    it "should ignore files that do not match the completion indicator" do
        entry_point = duck
        @execution_context_stub.stub!(:lookup_uri).and_return(entry_point)
        instance = Application.new()
        entry_point.should_not_receive(:marshal)

        instance.send(:on_file_created, 'ignored-file-name')
    end

    it "should pass on a message containing the name of the landing directory and an event header" do
        expected_message = Message.new
        expected_message.set_header(:event, :new_data)
        expected_message.set_header(:uri, URI.parse("lfs:/#{@landing}"))
        entry_point = duck
        @execution_context_stub.stub!(:lookup_uri).and_return(entry_point)
        FileWatcher.stub!(:new).and_return(dummy)
        #ExecutionContext.new.should equal(@execution_context_stub)
        #@execution_context_stub.lookup_uri("foo").should equal(entry_point)

        entry_point.should_receive(:marshal).once do |input_exchange|
            input_exchange.inbound.should eql(expected_message)
        end

        instance = Application.new
        instance.stub!(:bootstrap)
        instance.start()
        instance.send(:on_file_created, '.completed')
    end

    it "should pass on an instance method to the file watcher" do
        File.stub!(:directory?).and_return(true)
        watcher = FileWatcher.new("ignored")
        watcher.stub!(:start)
        FileWatcher.stub!(:new).and_return(watcher)
        @execution_context_stub.stub!(:lookup_uri).and_return(duck)
        instance = Application.new()
        instance.stub!(:bootstrap)
        instance.should_receive(:on_file_created).once.with("file")

        instance.start()
        watcher.instance_eval do
            @on_create.call("file")
        end
    end

    it "should start the watcher after initializing it" do
        entry_point = duck
        @execution_context_stub.stub!(:lookup_uri).and_return(entry_point)
        watcher = dummy
        FileWatcher.stub!(:new).and_return(watcher)
        #ExecutionContext.new.should equal(@execution_context_stub)
        #@execution_context_stub.lookup_uri("foo").should equal(entry_point)

        watcher.should_receive(:start).once.with(no_args())

        instance = Application.new
        instance.stub!(:bootstrap)
        instance.start()
    end

    it "should stop the watcher on demand" do
        entry_point = duck
        @execution_context_stub.stub!(:lookup_uri).and_return(entry_point)
        watcher = dummy
        FileWatcher.stub!(:new).and_return(watcher)
        instance = Application.new
        instance.stub!(:bootstrap)
        instance.start()

        watcher.should_receive(:stop).once.with(no_args())
        instance.stop()
    end
    
end
