#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

include MIS::Framework

describe "All filter factory behaviour", :shared => true do

    before :all do
        @parsing_filter = get_filter_factory
    end
    
    it "should throw an exception if the supplied 'environment_name' is invalid" do
        [nil, :invalid_environment, :invalid_environment2].each do |environment_name|
            lambda {
                @parsing_filter.new(environment_name)
            }.should raise_error(ArgumentError, "the 'environment_name' must be a known environment")
        end
    end
    
    [ :production, :sandbox].each do | env_name |
        it "should return a transformation filter in environment #{env_name}" do
            transform_filter = mock 'transformation filter'
            get_transformation_filter.should_receive( :new ).once.with( env_name ).and_return( transform_filter )
            factory = get_filter_factory.new( env_name )
            factory.get_transformation_filter().should equal( transform_filter )
        end
        
        it "should return a parsing filter instance for any given date in environment #{env_name}" do
            factory = get_filter_factory.new( env_name )
            expected_parsing_filter = get_parsing_filter_with_expectations_set( factory )
            factory = get_filter_factory.new( env_name )
            factory.get_parsing_filter( ).should equal( expected_parsing_filter )
        end
    end
    
    def create_expected_mock_parsing_filter
        grammar_file = File.join( $config.parser_grammar_definitions_dir, @grammar_file_name)
        grammar_text = ::IO.read( grammar_file )
        grammar_spec = eval( grammar_text )

        ::IO.should_receive( :read ).once.with( grammar_file ).and_return( grammar_text )

        real_grammar = Grammar.new { grammar_spec }
        Grammar.should_receive( :create ).once.with( :start, grammar_spec ).and_return( real_grammar )

        mock_parser = mock 'parser'
        Parser.should_receive( :new ).once.with( real_grammar, anything ).and_return( mock_parser )
        mock_parser.should_receive( :name= ).once.with( @parser_name )

        expected_parsing_filter = mock "parsing-filter"
        ParsingFilter.should_receive( :new ).once.with( mock_parser ).and_return( expected_parsing_filter )
        return expected_parsing_filter
    end
    
    def get_parsing_filter_with_expectations_set( factory )
        parsing_filter = cached_parsing_filter_instance( factory )
        return parsing_filter unless parsing_filter.nil?
        parsing_filter = create_expected_mock_parsing_filter    
        return parsing_filter
    end
    
    def cached_parsing_filter_instance( factory )
        factory.send( :instance_variable_get, "@parsing_filter_instance".to_sym )
    end
    
    def check_entry_filter_match(match, env_name, date)
        entry_filter = mock( "entry-filter-[#{match}]" )
        filters = [ entry_filter ]
        filter_lookup_results = filters.dup

        EntryFilter.should_receive( :new ) do |criteria, options|
            options[ :negate ].should be_true unless options.nil? || options.empty?  
            criteria.should eql( match )
            filter_lookup_results.shift
        end

        factory = get_filter_factory.new( env_name )
        result = factory.get_entry_filters(date)
        result.should eql( filters )
    end
end
