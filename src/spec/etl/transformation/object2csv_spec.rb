#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'
include BehaviourSupport

include MIS::Framework

#####################################################################################
##############                 Behaviour Support                    #################
#####################################################################################

#runtime const
delimited_by_tab = '|'

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( ObjectToCsvFileTransform ), 'when supplied with object data' do

    before :all do
        @@object_data = (1...20).collect do |counter|
            DummyEntry.new( "uuid#{counter}", "mail#{counter}", "cn#{counter}", "member#{counter}" )
        end
    end

    before :each do
        @file_spy = FileDouble.new
        File.stub!( :open ).and_yield( @file_spy )
        @transformer = ObjectToCsvFileTransform.new( 'file.csv', '|' )
    end

    [ :dataset, :options ].each do |required_argument|
        it "should validate the presence of the #{required_argument} argument before loading" do
            argument_order = { :dataset => 0, :options => 1 }
            arguments = [ :irrelevant, :sut_throws_before_using_us_anyway ]

            File.should_not_receive( :open )

            lambda do
                param_array = arguments.collect do |arg|
                    if arguments.index( arg ) == argument_order.fetch( required_argument )
                        nil
                    else
                        arg
                    end
                end
                @transformer.send( :transform, *param_array )
            end.should raise_error( ArgumentError )
        end
    end

    it 'should explode if no mapping rules are supplied' do
        lambda { @transformer.transform( @@object_data ) }.should raise_error( ArgumentError )
    end

    it 'should explode if invalid mapping rules are supplied' do

        bad_mappings = [
            [],
            [ :this_attribute_is_invalid, :and_so_is_this_one ],
            [ :uid, :mail, :cn, :member ].push( :one_last_invalid_attribute )
        ]

        example_runs = []

        bad_mappings.each do |invalid_mapping_rule_collection|
            example_runs << lambda {
                @transformer.transform( @@object_data, :mapping => invalid_mapping_rule_collection )
            }
        end

        example_runs.each { |bad_mapping_example|
            bad_mapping_example.should raise_error( InvalidMappingException )
        }
    end

    it 'should explode when passed an object which cannot be mapped properly' do
        class Foo; end;
        lambda do
            @transformer.transform( Foo.new, :mapping => [ :non_existent_attribute ] )
        end.should raise_error( InvalidMappingException )
    end


    it 'should wrap all execution time errors appropriately' do
        File.stub!( :open ).and_raise IOError
        lambda {
            @transformer.transform(
                @@object_data,
                :mapping => [ :uid, :mail, :cn, :member ]
            )
        }.should raise_error( TransformError )
    end

    it 'should write a line for each entry in an array supplied to #transform' do
        @transformer.transform(
            @@object_data,
            :mapping => [ :uid, :mail, :cn, :member ]
        )
        @@object_data.each do |entry|
            @file_spy.data.should include( entry.as_delimited_text( delimited_by_tab ) )
        end
    end

    it 'should write a line for a single entry supplied to #transform' do
        entry = DummyEntry.new( 'urn:uuid:abcd-etc', 'tim.watson@sb-domain.com', 'cn=me', 'membership stuff' )
        @transformer.transform(
            entry,
            :mapping => [ :uid, :mail, :cn, :member ]
        )
        @file_spy.data.should include( entry.as_delimited_text( delimited_by_tab ) )
    end

end
