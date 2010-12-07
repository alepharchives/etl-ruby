#!/usr/bin/env ruby

require 'rubygems'

include ETL

module ETL
    module Transformation
        module Pipeline
            module Filters

                class ParsingFilter

                    mixin Validation

                    def initialize( parser )
                        validate_arguments binding()
                        @parser = parser
                    end

                    def filter( input, filter_chain )
                        filter_chain.proceed( parse_input( input ) )
                    end

                    private

                    def parse_input( input )
                        @parser.parse( input )
                    rescue ParseError => parseEx
                        raise FilterException.new(
                            parseEx.message,
                            self,
                            input,
                            parseEx
                        ), parseEx.message, caller
                    end

                end

            end
        end
    end
end
