#!/usr/bin/env ruby
 
require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe "All EndpointFilter behaviour", :shared => true do

    it_should_behave_like "All tested constructor behaviour"
    
    before :all do
        @clazz = EndpointFilter
        @constructor_args = [ 'endpoint', 'filter', 'execution_context' ]
        @context = dummy
    end
    
end

describe given( ETL::Integration::Engine::Endpoints::EndpointFilter ), 'when acting as a producer' do
    
    it_should_behave_like "All EndpointFilter behaviour"
    
    it 'should not return exchanges which the filter rejects' do
        ep = dummy
        filter = mock 'rule based filter'
        ep.stub!( :unmarshal ).and_return( dummy, dummy, dummy, nil )
        filter.stub!( :evaluate ).and_return( false )
        
        endpoint = EndpointFilter.new( ep, filter, @context )
        4.times { endpoint.unmarshal().should be_nil }
    end
    
    it 'should only return exchanges which the filter accepts' do
        ep = dummy
        filter = mock 'rule-based-filter'
        ep.stub!( :unmarshal ).and_return( dummy, dummy, final_exchange=dummy )
        
        filter.should_receive( :evaluate ).at_least( 3 ).times.and_return( false, false, false, true )
        
        endpoint = EndpointFilter.new( ep, filter, @context )
        endpoint.unmarshal().should equal( final_exchange )
    end
    
end
    
describe given( ETL::Integration::Engine::Endpoints::EndpointFilter ), 'when acting as a consumer' do
    
    it_should_behave_like "All EndpointFilter behaviour"
    
    it 'should only marshal exchanges which the filter accepts' do
        ep = dummy
        filter = mock 'filter mock'
        filter.stub!( :evaluate ).and_return( true )
        input_exchange = dummy
        
        ep.should_receive( :marshal ).once.with( input_exchange )
        
        endpoint = EndpointFilter.new( ep, filter, @context )
        endpoint.marshal( input_exchange )
    end
    
    it 'should not marshal exchanges which the filter rejects' do
        ep = dummy
        filter = mock 'some filter'
        filter.stub!( :evaluate ).and_return( false )
        
        ep.should_not_receive( :marshal )
        
        endpoint = EndpointFilter.new( ep, filter, @context )
        endpoint.marshal( dummy )
    end
    
end
