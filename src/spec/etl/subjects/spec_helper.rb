#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

#TODO: move the filter exception into MIS::Transformation::Pipeline ???
include MIS::Framework

#######################################################################################
################                 Behaviour Support                     ################
#######################################################################################

module UsageTransformationFilterBehaviourSupport
    
    def get_system_under_test
        UsageTransformationFilter
    end

    def get_parsing_filter
        if $parsing_filter.nil?
            factory = CapabilityUsageFilterFactory.new( :sandbox )
            $parsing_filter = factory.get_parsing_filter            
        end
        return $parsing_filter
    end
end

module ParsingFilterBehaviourSupport

    def validate_invalid_token_handling( input_data, index )
        lambda do
            begin
                @filter.filter( input_data.join( ' ' ), @mock_filter_chain )
            rescue FilterException => err
                validate_parse_error( input_data, index, err.cause )
                raise err, err.message, caller
            end
        end.should raise_error( FilterException )
    end

    def validate_valid_token_handling( input_data )
        @filter.filter( input_data, @mock_filter_chain)
    end

    def validate_parse_error( input_data, index, err )
        err.should be_an_instance_of( ParseError )
        line = err.error_data.raw_input
        line.should eql( input_data.join(' ') )
        states = err.error_data.states
        #puts "we have #{states.size} states in our error data stack and the index we're checking is #{index}"
        states.should have( index + 2 ).items
        states.each_with_index do |state, idx|
            if state == states.last
                state.should be_error
            elsif state == states.first
                state.token.should eql(nil)
            else
                state.token.should eql( input_data[ idx - 1 ] )
            end
        end
    end

end
