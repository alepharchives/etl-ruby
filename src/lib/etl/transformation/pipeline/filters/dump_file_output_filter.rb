#!/usr/bin/env ruby

require 'rubygems'

include ETL

module ETL
    module Transformation
        module Pipeline
            module Filters
                class DumpFileOutputFilter

                    mixin Validation

                    def initialize output_writer
                        validate_arguments binding()
                        @writer = output_writer
                    end

                    def filter( input, filter_chain )
                        @writer << input
                    rescue RuntimeError => ex
                        raise FilterException.new(
                            ex.message,
                            self,
                            input,
                            ex
                        ), ex.message, caller
                    end
                end
            end
        end
    end
end
