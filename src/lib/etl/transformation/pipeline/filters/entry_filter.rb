#!/usr/bin/env ruby

require 'rubygems'

include ETL

module ETL
    module Transformation
        module Pipeline
            module Filters

                class EntryFilter

                    mixin Validation

                    # Initializes the EntryFilter class.
                    # filter_phrase: the pattern to use when matching inputs
                    # options: an opt-hash containing the
                    #   following options => :negate (reject matching inputs)
                    #
                    def initialize( filter_phrase=//, options={} )
                        validate_arguments binding()
                        @filter_phrase = filter_phrase
                        @negate = options[ :negate ]
                    end

                    def filter( input, filter_chain )
                        validate_arguments binding(), :filter_chain
                        filter_chain.proceed( input ) if match? input
                    end

                    private

                    def match?( input )
                        match = input =~ @filter_phrase
                        return ( @negate ) ? !match : match
                    end

                end

            end
        end
    end
end
