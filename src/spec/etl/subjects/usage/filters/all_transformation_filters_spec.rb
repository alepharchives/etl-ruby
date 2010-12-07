#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

include MIS::Framework

describe "All transformation filter behaviour", :shared => true do

    before :all do
        @parsing_filter = get_parsing_filter
    end

    it 'should explode if the environment argument is nil' do
        lambda { get_system_under_test.new( nil ) }.should raise_error( ArgumentError )
    end

    it 'should extract the valid fields from the log line' do
        expectation_verifying_filter_chain = mock( 'filter-chain' )
        expectation_verifying_filter_chain.should_receive( :proceed ) do |input|
            verify_input_expectations( input )
        end
        transformation_filter = get_system_under_test.new( get_environment_name )
        lambda {
            transformation_filter.filter( get_parser_states, expectation_verifying_filter_chain )
        }.should_not raise_error
    end

    it 'should wrap any errors in a filter exception' do
        mock_transformer = mock( 'transformer', :null_object => true )
        StateTokenTransformer.stub!( :new ).and_return( mock_transformer )
        mock_transformer.should_receive( :collect ).with( any_args ).and_raise( StandardError )

        transformation_filter = get_system_under_test.new( get_environment_name )
        lambda {
            transformation_filter.filter( ignored = [], missing_chain = nil )
        }.should raise_error( FilterException )
    end

    def get_parser_states
        @states ||= do_get_parser_states
    end

    def do_get_parser_states
        log_line = get_log_line
        result = nil
        do_nothing_filter_chain = mock( 'ignorant-filter-chain' )
        do_nothing_filter_chain.should_receive( :proceed ) do |input|
            result = input
        end
        begin
            @parsing_filter.filter( log_line, do_nothing_filter_chain )
        rescue StandardError => err

            #TODO: REFACTOR:
            # this code is now duplicated here and in the logfile transformation integration test spec...
            #
            # this should be part of a debugging support policy api implementation.
            #
            # change it quickly, before somebody notices!!! :P

            cause = err
            parse_ex = cause.cause
            data = parse_ex.error_data
            puts "dump..."
            puts "filter type = [ #{cause.filter.class} ]"
            puts "parser instance = [ #{cause.filter.instance_eval { @parser.name } } ]"
            puts "raw input = [ #{data.raw_input} ]"
            #todo: walk the stack by hand!!!
            error_state = data.states.last
            puts "error state = [ @name=#{error_state.name}, @token=#{error_state.token} ]"
            pstate = data.states[ data.states.size - 2 ]
            puts "penultimate state = [ @name=#{pstate.name}, @token=#{pstate.token} ]"
            raise parse_ex
        end
        result
    end

    def get_environment_name
        default_env = 'env'
    end

    def method_missing( sym, *args )
        return super unless [
            :verify_input_expectations,
            :get_system_under_test,
            :get_parsing_filter,
            :get_log_line
        ].include?( sym )
        raise NoMethodError, "the #{sym} method should be implemented in your behaviour spec(s)!", caller
    end
    
    def null_string
        return 'NULL'
    end

end
