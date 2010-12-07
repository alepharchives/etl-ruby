#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given(ETL::Integration::Engine::DSL::RouteBuilder) do

    it_should_behave_like "All tested constructor behaviour"
    #it_should_behave_like "All Builder behaviour"

    before :all do
        @clazz = RouteBuilder
        @constructor_args = [ 'context' ]
        #@method_name = :to
    end

    it "should not support source uri declarations" do
        RouteBuilder.new(dummy).should_not respond_to(:from)
    end

    it "should not call the context/registry if the supplied object already responds to 'unmarshal'" do
        endpoint = dummy
        endpoint.stub!(:respond_to?).and_return(true)
        context = dummy
        context.should_not_receive(:resolve_endpoint_uri)
        builder = RouteBuilder.new(context)
        builder.where(duck).to(duck).and.where(duck).to(duck).product()
    end

    it "should explode if the supplied expression is nil" do
        lambda {
            RouteBuilder.new(dummy).where(nil)
        }.should raise_error(ArgumentError, "the 'expression' argument cannot be nil")
    end

    it "should explode unless the supplied expression responds to 'evaluate'" do
        expression = dummy
        expression.stub!(:respond_to?).and_return(false)
        lambda {
            RouteBuilder.new(dummy).where(expression)
        }.should raise_error(InvalidExpressionException)
    end

    it "should explode if the expression has already been set" do
        lambda {
            builder = RouteBuilder.new(dummy)
            builder.where(duck).where(duck)
        }.should raise_error(InvalidOperationException)
    end

    it "should respond to 'via'" do
        RouteBuilder.new(dummy).should respond_to(:via)
    end

    [ :and, :or ].each do |router_type|
        it "should explode if you try to add an '#{router_type}' route before setting the condition" do
            lambda {
                RouteBuilder.new(dummy).send(router_type)
            }.should raise_error(InvalidOperationException)
        end

        it "should explode if you try to add an '#{router_type}' route after setting the condition but prior to setting the destination" do
            lambda {
                RouteBuilder.new(dummy).where(duck).send(router_type)
            }.should raise_error(InvalidOperationException, "The current route specification has no destination set.")
        end

        it "should explode if you try to add an '#{router_type}' route after setting the destination but prior to setting the condition" do
            lambda {
                RouteBuilder.new(dummy).to(duck).send(router_type)
            }.should raise_error(InvalidOperationException, "The current route specification has no condition set.")
        end

        it "should create a new route specification when you add an '#{router_type}' route" do
            builder = RouteBuilder.new(dummy).where(duck).to(duck).via(duck, duck)
            lambda {
                builder.send(router_type)
            }.should change(builder, :current_specification)
        end
    end

    it "should set the supplied condition on the current route specification" do
        builder = RouteBuilder.new(dummy)
        lambda {
            builder.where(duck)
        }.should change(builder, :current_specification)
    end

    it "should set any/all steps for the current route specification" do
        builder = RouteBuilder.new(dummy)
        lambda {
            builder.via(duck, duck)
        }.should change(builder, :current_specification)
    end

    it "should set the destination on the current route specification" do
        builder = RouteBuilder.new(dummy)
        lambda {
            builder.to(duck)
        }.should change(builder, :current_specification)
    end

    it "should change the router_type when you add an inclusive route (based on the method called)" do
        builder = RouteBuilder.new(dummy).where(duck).to(duck)
        lambda {
            builder.and()
        }.should change(builder, :router_type).to(MulticastRouter)
    end

    it "should change the router_type when you add an exclusive route (based on the method called)" do
        builder = RouteBuilder.new(dummy).where(duck).to(duck)
        lambda {
            builder.or()
        }.should change(builder, :router_type).to(Router)
    end

    it "should explode if you try to change the router type to :or after setting it initially to :and" do
        builder = RouteBuilder.new(dummy).where(duck).to(duck).and()
        lambda {
            builder.or()
        }.should raise_error(InvalidOperationException, "The router type has already been set to 'and' and cannot be changed!")
    end

    it "should explode if you try to change to router type to :and after setting it initially to :or" do
        builder = RouteBuilder.new(dummy).where(duck).to(duck).or()
        lambda {
            builder.and()
        }.should raise_error(InvalidOperationException, "The router type has already been set to 'or' and cannot be changed!")
    end

    it "should resolve each route to an endpoint if no 'via' steps have been declared" do
        File.stub!(:directory?).and_return(true)
        context = mock 'context test spy . . .'
        context.should_receive(:lookup_uri).twice.and_return(duck)
        RouteBuilder.new(context).where(duck).to("lfs://usr/bin").and.where(duck).to("lfs://opt/jboss").product()
    end
    
    it "should explode unless the supplied endpoint responds to :unmarshal" do
        context = dummy
        bad_endpoint = dummy
        context.stub!(:lookup_uri).and_return(bad_endpoint)
        bad_endpoint.stub!(:respond_to?).and_return(false)
        lambda {
            RouteBuilder.new(context).where(duck).to("foo://not-a-valid-endpoint-uri").product()
        }.should raise_error(UnresolvableUriException)
    end

    it "should return a product based on its router_type" do
        [ :and, :or ].each do |router_type|
            builder = RouteBuilder.new(dummy).where(duck).to(duck).send(router_type).where(duck).to(duck)
            builder.product().should be_an_instance_of(builder.router_type)
        end
    end

    it "should resolve a route to a pipeline processor wrapped in an endpoint when a route has some 'via' steps declared" do
        context = dummy
        first_endpoint = "lfs://foo/bar.baz"
        second_endpoint = "lfs://flobby/wibbly/wobbly/wibble"
        context.stub!(:lookup_uri).and_return(dummy_uri=duck)
        dummy_uri.stub!(:uri).and_return( first_endpoint, second_endpoint )
        PipelineConsumer.stub!(:new).and_return(dummy_pipeline_processor=duck)

        ProcessorEndpoint.should_receive(:new).once.with(first_endpoint, context, dummy_pipeline_processor).and_return(duck)
        ProcessorEndpoint.should_receive(:new).once.with(second_endpoint, context, dummy_pipeline_processor).and_return(duck)

        RouteBuilder.new(context).where(duck).to(first_endpoint).
            via(Processor.new {}).and.where(duck).to(second_endpoint).via(Processor.new {}).product()
    end

    it "should resolve from 'route' to 'to' properly" do
        builder = RouteBuilder.new(dummy)
        expression, dest = duck, duck
        builder.instance_eval do
            where(expression).to(dest)
        end
        builder.current_specification.destination.should_not be_nil
    end
    
    it "should explode if you call otherwise before a valid initial route has been set" do
        builder = RouteBuilder.new(dummy)
        [ :where, :to ].each do |thing_that_needs_setting|
            lambda { builder.otherwise() }.should raise_error(InvalidOperationException)
            builder.send(thing_that_needs_setting, duck)
        end
        lambda {
            builder.and.where(duck).to(dummy).otherwise()
        }.should_not raise_error
    end
    
    it 'should explode if you call otherwise before a router type has been set' do
        builder = RouteBuilder.new(dummy)
        
        lambda {
            builder.where(duck).to(dummy).otherwise()
        }.should raise_error(InvalidOperationException, "Cannot set 'otherwise' clause before setting a router type (e.g. and/or).")
    end
    
    
    it 'should change the current specification when otherwise is called' do
        builder = RouteBuilder.new(dummy)
        lambda {
            set_otherwise_on_builder(builder)
        }.should change(builder, :current_specification)
    end
    

    it "should add a truth route whenever the 'otherwise' clause is supplied" do
        builder = RouteBuilder.new(dummy)
        set_otherwise_on_builder(builder)
        
        builder.current_specification.expression.evaluate(dummy).should be_true        
    end
    
    it "should add a dead letter channel when you tell it to ignore messages" do
        builder = RouteBuilder.new(dummy)
        set_otherwise_on_builder(builder)
        builder.should_not_receive(:prepare_next_route)
        builder.ignore()
        builder.current_specification.destination.should be_an_instance_of(DeadLetterChannel)
    end
    
    it "should explode if you try and set 'ignore' in an invalid context" do
        lambda {
            RouteBuilder.new(dummy).ignore()
        }.should raise_error(InvalidOperationException)
    end
    
    it "should return all services it depends on" do
        dependencies = ["file://mount/dataext/fallout.cmj", "file://${config.dump}/targets/${edif}.cmj"]
        builder = RouteBuilder.new(dummy)
        
        builder.where(duck).to(dependencies[0]).and.where(duck).to(dependencies[1])

        builder.depends_on.should eql( dependencies )
    end
    
    def set_otherwise_on_builder(builder)
        builder.where(duck).to(dummy).and.where(duck).to(dummy).otherwise()
    end

end
