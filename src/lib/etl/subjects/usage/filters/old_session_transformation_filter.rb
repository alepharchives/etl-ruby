#!/usr/bin/env ruby

require 'rubygems'
require 'delegate'

include ETL
include ETL::Transformation
include ETL::Transformation::Pipeline::Filters

module ETL
    module Subjects
        module Usage
            module Filters
                class OldSessionTransformationFilter

                    mixin TransformationFilterSupport

                    ExtractValueUnalteredMode = lambda { |input| input }
                    NullStringMode = lambda { |input| 'NULL' }

                    def initialize( environment )
                        validate_arguments( binding() )
                        @environment = environment
                        @transformer = StateTokenTransformer.new
                        @transformer.get( :date ).from_state( :date ).using( &ExtractValueUnalteredMode )
                        @transformer.get( :time ).from_state( :time ) do |input|
                            extract_service_invocation_time( input )
                        end
                        @transformer.get( :certificate_guid ).from_state( :app_id, :early_app_id ) do |input|
                            self.send( :strip_square_brackets, input )
                        end
                        @transformer.get( :caller_number ).from_state( :end ) do |input|
                            match = match_caller_data( input )
                            strip_stupid_characters_from_endpoint_uri( match[2] )
                        end
                        @transformer.get( :caller_endpoint_kind ).from_state( :end ) do |input|
                            match = match_caller_data( input )
                            ep_kind = match[1] || ''
                            self.send( :extract_endpoint_kind, ep_kind )
                        end
                        @transformer.get( :callee_number ).from_state( :end ) do |input|
                            match = match_callee_data( input )
                            strip_stupid_characters_from_endpoint_uri( match[2] )
                        end
                        @transformer.get( :callee_endpoint_kind ).from_state( :end ) do |input|
                            match = match_callee_data( input )
                            ep_kind = match[1] || ''
                            self.send( :extract_endpoint_kind, ep_kind )
                        end
                        @transformer.get( :transaction_id ).from_state( :txn_id, :txn_id2 ) do |input|
                            self.send( :strip_square_brackets, input )
                        end
                    end

                    private

                    def match_caller_data( input )
                        match = input.match( /(?:\[)([\w]{3}\:)?([^,]*)(?=,)/ )
                    end

                    def match_callee_data( input )
                        match = input.match( /(?:[,\s]{2})([\w]{3}\:)?([^,]*)(?=,)/ )
                    end

                    def transform_input_states( states )
                        transformed_data = @transformer.collect( states )
                        txn_id = transformed_data.pop()
                        transformed_data + (1..3).to_a.fill( 'NULL' ).push(txn_id )
                    end

                end
            end
        end
    end
end
