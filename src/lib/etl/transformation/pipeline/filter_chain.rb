#!/usr/bin/env ruby

require 'rubygems'

include ETL
include ETL::Transformation
include ETL::Transformation::Pipeline::Filters

module ETL
    module Transformation
        module Pipeline

            #REFACTOR: is this class in the correct module!?

            class FilterChain

                mixin Validation

                def process( input )
                    guard_state_invariants
                    process_handler = FilterChainInvocationHandler.new( @filters.dup )
                    process_handler.apply_filters( input )
                end

                def add_filter( filter )
                    (@filters ||= []).push filter
                end
                
                private

                def guard_state_invariants
                    validate_instance_variables( binding(), :filters ) {
                        raise MissingFilterException.new( "no 'filters' set" )
                    }
                end

                private

                class FilterChainInvocationHandler
                    initialize_with :filters, :validate => true

                    def apply_filters( input )
                        proceed( input )
                    end

                    def proceed( input )
                        return input if @filters.empty?
                        @filters.shift.filter( input, self )
                    rescue FilterException => ex
                        raise ex
                    rescue StandardError => err
                        raise TransformError.new( err.message || $!, self, err )
                    end
                end
            end

        end
    end
end
