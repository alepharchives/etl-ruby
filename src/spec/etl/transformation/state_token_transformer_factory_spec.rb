#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'

include BehaviourSupport
include ETL::Transformation

describe given( StateTokenTransformerFactory ) do

    it "should create a transformer given a file uri and environment" do
        # prepare
        env = 'sandbox'
        file_uri = "mock.xformer"
        mock_xformer = mock( 'xformer' )

        # expectations
        StateTokenTransformer.should_receive( :new ).and_return( mock_xformer )
        mock_xformer.should_receive( :load_mapping_rules ).with( file_uri )
        mock_xformer.should_receive( :environment= ).with( env )
        
        # act
        StateTokenTransformerFactory.get_transformer( file_uri, env ).should equal( mock_xformer )
    end
    
    it "should cache transformers for the same file uri's" do
        # expectations
        mock_xformer = mock( 'xformer' )
        mock_xformer.should_receive( :environment= ).twice
        mock_xformer.should_receive( :load_mapping_rules ).twice
        StateTokenTransformer.should_receive( :new ).twice.and_return( mock_xformer )
        
        # act
        StateTokenTransformerFactory.get_transformer( "some.xformer", "sandbox" )
        StateTokenTransformerFactory.get_transformer( "other.xformer", "sandbox" )
        StateTokenTransformerFactory.get_transformer( "some.xformer", "sandbox" )
        StateTokenTransformerFactory.get_transformer( "other.xformer", "sandbox" )
    end
end