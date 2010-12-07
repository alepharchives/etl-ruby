#!/usr/bin/env ruby

require 'rubygems'

#TODO: this file should be named exception.rb!!!

module ETL
    module Transformation

        # I am the base class for all transformation errors and exceptions.
        class TransformError < BaseException

            attr_reader :message, :inner_exception, :transformer

            def initialize( message=$!, transformer=nil, inner_exception=$ERROR_INFO )
                local_variables.each { |var| instance_variable_set( "@#{var}", eval( var ) ) }
            end

#            alias cause inner_exception
            
            def body()
                # TODO: Find the useful values to return
            end
        end

        # I am raised when a given set of mappings are not valid, given
        # the state of the transform or underlying data structures.
        class InvalidMappingException < TransformError

            attr_reader :mapping_rules, :mapping_target

            def initialize( message=$!, mapping_target=nil, mapping_rules=nil, cause=$ERROR_INFO )
                super( message, mapping_target, cause )
                @mapping_rules = mapping_rules
            end

            alias mapping_target transformer
        end

    end
end
