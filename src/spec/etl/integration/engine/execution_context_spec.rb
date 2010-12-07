#!/usr/bin/env ruby

require 'rubygems'
require "yaml"
require 'spec'

require File.dirname(__FILE__) + '/../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

describe "All context behaviour", :shared => true do
    before :each do
        [ :directory?, :file? ].each do |method_name|
            File.stub!(method_name).and_return(true)
        end
    end
end

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given(ETL::Integration::Engine::ExecutionContext), "when initializing the context" do

    it "should lookup the configuration file without a path by default" do
        File.should_receive(:resolve_path).once.with("~/config.yaml")
        File.stub!(:open).and_return(dummy)
        YAML.stub!(:load).and_return( {} )
        ExecutionContext.new.config().send(:load_config)
    end
    
end

describe given(ETL::Integration::Engine::ExecutionContext), "when used as a service/endpoint registry" do

    it_should_behave_like "All context behaviour"

    [ :lfs, :file, :postgres].each do |endpoint_kind|
        it "should automatically register an endpoint if a lookup is performed on a uri for the '#{endpoint_kind}' scheme" do
            context = ExecutionContext.new
            endpoint = dummy
            endpoint.stub!(:scheme).and_return(endpoint_kind.to_s)
            endpoint.stub!(:path).and_return('ignored')
            lambda do
                context.lookup_uri(endpoint)
            end.should change(context, :endpoints)
        end
    end

    it "should create a DatabaseEndpoint for a 'postgres' uri" do
        dummy_ep = dummy
        dummy_ep.stub!(:scheme).and_return('postgres')
        context = ExecutionContext.new()
        DatabaseEndpoint.should_receive(:new).once.with(dummy_ep, context).and_return(duck)
        context.lookup_uri(dummy_ep)
    end

    it "should create a DirectoryEndpoint for an 'lfs' uri" do
        File.stub!(:directory?).and_return(true)
        endpoint = dummy
        endpoint.stub!(:scheme).and_return('lfs')
        endpoint.stub!(:full_path).and_return("foo bar uri path...")
        context = ExecutionContext.new
        DirectoryEndpoint.should_receive(:new).once.with(endpoint, context).and_return(duck)
        context.lookup_uri(endpoint)
    end

    it "should create a FileEndpoint for a 'file' uri" do
        endpoint = dummy
        endpoint.stub!(:scheme).and_return('file')
        endpoint.stub!(:path).and_return('ignored...')
        context = ExecutionContext.new
        FileEndpoint.should_receive(:new).once.with(endpoint, context).and_return(duck)
        context.lookup_uri(endpoint)
    end

    it "should return the same endpoint after an initial lookup is performed" do
        [ :lfs, :file, :postgres ].each do |endpoint_kind|
            context = ExecutionContext.new
            if endpoint_kind.eql? :postgres
                endpoint = "postgres://localhost:5432/DATABASE_NAME?user=user&password=password"
            else
                endpoint = "#{endpoint_kind}://myhostname/54321/path"
            end
            result = context.lookup_uri(endpoint)
            result.should equal(context.lookup_uri(endpoint))
        end
    end

    it "should explode if an 'etl' endpoint lookup is performed on an unregistered uri" do
        lambda {
            uri = dummy
            uri.stub!(:scheme).and_return('etl')
            ExecutionContext.new.lookup_uri(uri)
        }.should raise_error(UnresolvableUriException)
    end

    it "should silently convert a uri string to a uri before performing a lookup" do
        endpointuri = "file://foo.bar/baz/myfile.csv"
        URI.should_receive(:parse).once.with(endpointuri).and_return(duck)
        ExecutionContext.new().lookup_uri(endpointuri)
    end

end

describe given(ETL::Integration::Engine::ExecutionContext), "when registering services and endpoints" do

    it_should_behave_like "All context behaviour"

    it "should explode if you try to register something twice" do
        context = ExecutionContext.new
        context.send(:register, 'etl://foo', duck)
        lambda {
            context.send(:register, 'etl://foo', duck)
        }.should raise_error(InvalidOperationException, "The uri 'etl://foo' has already been registered.")
    end

    it "should add a registered 'etl' endpoint to the list of endpoints" do
        context = ExecutionContext.new
        endpoint = FileEndpoint.new('file://foo.txt', context)
        lambda {
            context.register_endpoint(endpoint)
        }.should change(context, :endpoints)
    end

    it "should explode unless the supplied endpoint responds to the methods of the 'producer' and 'consumer' endpoint interface(s)" do
        endpoint = dummy
        endpoint.stub!(:respond_to?) { |method_name| true if [:marshal, :uri].include?(method_name) }
        lambda {
            begin
                context = ExecutionContext.new
                context.register_endpoint(endpoint)
            rescue Exception => ex
                ex.context.should equal(context)
                ex.endpoint.should equal(endpoint)
                ex.uri.should eql("Unknown uri.")
                ex.message.should eql("An endpoint must respond to 'unmarshal' to be eligable for registration.")
                raise()
            end
        }.should raise_error(EndpointRegistrationException)
    end

    it "should explode unless the supplied endpoint responds to the methods of the 'producer' and 'consumer' endpoint interface(s)" do
        endpoint = dummy
        def endpoint.unmarshal()
            return 'ignored'
        end
        lambda {
            ExecutionContext.new.register_endpoint(endpoint)
        }.should raise_error(EndpointRegistrationException)
    end

    it "should explode unless the supplied service responds to 'marshal'" do
        lambda {
            ExecutionContext.new.register_service(dummy)
        }.should raise_error(EndpointRegistrationException, "A service must respond to 'marshal' to be eligable for registration.")
    end

    it "should make a service available via a lookup_uri call once it has been registered" do
        context = ExecutionContext.new
        serviceuri = "etl://myservice/foo/bar"
        service = duck
        service.stub!(:uri).and_return(serviceuri)
        context.register_service(service)
        context.lookup_uri(serviceuri).should equal(service)
    end

    it "should make an endpoint available via a lookup_uri call once it has been registered" do
        context = ExecutionContext.new
        endpointuri = "etl://myendpoint/foo/bar"
        endpoint = duck
        endpoint.stub!(:uri).and_return(endpointuri)
        context.register_endpoint(endpoint)
        context.lookup_uri(endpointuri).should equal(endpoint)
    end

    it "should explode unless the supplied pipeline processor responds to 'process'" do
        lambda {
            ExecutionContext.new.register_pipeline(Pipeline.new("etl://standalone-pipeline", duck, duck))
        }.should raise_error(EndpointRegistrationException, "A pipeline processor must respond to 'process' to be eligable for registration.")
    end

    it "should explode unless the supplied pipeline processor responds to 'pipeline'" do
        lambda {
            ExecutionContext.new.register_pipeline(Processor.new {})
        }.should raise_error(EndpointRegistrationException, "A pipeline processor must respond to 'pipeline' to be eligable for registration.")
    end

    it "should register both the pipeline and the processor as a service for other consumers" do
        pipelineuri = "etl://mypipeline"
        pipeline = dummy
        pipeline.stub!(:uri).and_return(pipelineuri)
        executor = PipelineProcessor.new(pipeline, duck, duck)
        context = ExecutionContext.new
        context.should_receive(:register).once.with("#{pipelineuri}/processor", executor)
        context.should_receive(:register_service).once.with(pipeline)

        context.register_pipeline(executor)
    end

    it "should explode when registering a consumer unless it responds to 'process'" do
        lambda {
            ExecutionContext.new.register_consumer(dummy)
        }.should raise_error(EndpointRegistrationException, "A consumer must respond to 'process' to be eligable for registration.")
    end

    it "should make a consumer available via a lookup_uri call once it has been registered" do
        context = ExecutionContext.new
        serviceuri = "etl://myservice2/foo/bar"
        service = duck
        service.stub!(:uri).and_return(serviceuri)
        context.register_consumer(service)
        context.lookup_uri(serviceuri).should equal(service)
    end

    it "should convert a consumer to a processor endpoint if the 'api' query string calls for 'marshal'" do
        context = ExecutionContext.new
        consumer = dummy
        consumeruri = "etl://myconsumer"
        def consumer.process(exchange)
            puts exchange
        end
        consumer.stub!(:uri).and_return(consumeruri)
        context.register_consumer(consumer)

        context.lookup_uri("etl://myconsumer?api=marshal").should respond_to(:marshal)
    end

    it "should explode if you try to do a pipeline lookup with an unsupported api conversion" do
        context = ExecutionContext.new
        pipeline = Pipeline.new("etl://mypipeline5", context, duck)
        executor = PipelineProcessor.new(pipeline, duck, duck)
        context.register_pipeline(executor)

        lambda {
            context.lookup_uri("etl://mypipeline5?api=nosuchapi")
        }.should raise_error(ServiceNotFoundException, "The api conversion 'nosuchapi' failed.")
    end

    it "should explode if you try to register a raw pipeline minus the processsor" do
        context = ExecutionContext.new
        pipeline = Pipeline.new("etl://standalonepipeline", context, duck)
        lambda {
            context.register_pipeline(pipeline)
        }.should raise_error(EndpointRegistrationException, "A pipeline processor must respond to 'process' to be eligable for registration.")
    end

    #TODO: put some tests in around dealing with pipelines!
    it "should convert a pipeline uri lookup with an ?api=process query string into a differet uri (adding the /processor path)" do
        context = ExecutionContext.new
        uri = "etl://mypipeline6"
        pipeline = Pipeline.new(uri, context, duck)
        processor = PipelineProcessor.new(pipeline, duck, duck)
        context.register_pipeline(processor)

        context.lookup_uri("#{uri}?api=process").should equal(processor)
    end


    #TODO: reconsider this in light of the changes to registration behaviour
    #    it "should explode if you try to convert a pipeline for which no executor is registered" do
    #        context = ExecutionContext.new
    #        pipeline = Pipeline.new("etl://mypipeline5", context, duck)
    #        context.register_pipeline(pipeline)
    #
    #        lambda {
    #            context.lookup_uri("etl://mypipeline5?api=process")
    #        }.should raise_error(ServiceNotFoundException, "The api conversion 'process' failed.")
    #    end

    #TODO: reconsider this test, as i wouldn't really expect it to behave this way...
    #    it "should convert a pipeline to a pipeline consumer and then to a processor endpoint" do
    #        context = ExecutionContext.new
    #        pipeline = Pipeline.new("etl://mypipeline123", context, duck, duck)
    #        executor = PipelineProcessor.new(pipeline, duck, duck)
    #        context.register_pipeline(executor)
    #
    #        context.lookup_uri("etl://mypipeline123?api=marshal").should respond_to(:marshal)
    #    end

    it "should explode if you try to do a consumer lookup with an unsupported api conversion" do
        context = ExecutionContext.new
        consumer = PipelineConsumer.new("etl://somepipelineconsumer", context, duck, duck)
        context.register_consumer(consumer)

        lambda {
            context.lookup_uri("etl://somepipelineconsumer?api=nosuchapi")
        }.should raise_error(ServiceNotFoundException, "The api conversion 'nosuchapi' failed.")
    end

    it "should wrap an endpoint (or service) that reponds to 'marshal' in an endpoint processor when the requested api conversion is 'process'" do
        context = ExecutionContext.new
        uri = "etl://myservice/foo/bar/ok"
        service = Service.new(uri, context, duck)
        context.register_service(service)

        context.lookup_uri("#{uri}?api=process").should be_an_instance_of(EndpointProcessor)
    end

    it "should convert a consumer (processor) to a processor endpoint when the requested api conversion is 'marshal'" do
        context = ExecutionContext.new
        consumeruri = "etl://myconsumer"
        consumer = PipelineConsumer.new(consumeruri, context, duck, duck)
        context.register_consumer(consumer)

        context.lookup_uri("#{consumeruri}?api=marshal").should be_an_instance_of(ProcessorEndpoint)
    end

    it "should return a DefaultFaultChannel as the default fault channel object if default fault is not configured" do
        context = ExecutionContext.new
        context.default_fault_channel.class.should eql(DefaultErrorChannel)
    end
    
    it "should return the specified default fault channel if default fault channel is configured" do
        expected_fault_channel = DatabaseErrorChannel.new(dummy)
        context = ExecutionContext.new
        context.default_fault_channel = expected_fault_channel
        context.default_fault_channel.class.should eql(DatabaseErrorChannel)
    end
end
