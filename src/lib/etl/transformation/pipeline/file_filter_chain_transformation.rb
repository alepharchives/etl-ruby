#!/usr/bin/env ruby
 
require 'rubygems'
require 'faster_csv'

module ETL
    module Transformation
        module Pipeline
            
            # I am a file format transformation.
            # I delegate to a chain of supplied filters to perform
            # formating/conversion from one file format to another.
            class FileFilterChainTransformation

                mixin Validation

                def initialize( *filters )
                    unless filters.size >= 1
                        raise ArgumentError, 'at least one filter object is required', caller
                    end                        
                    @filters = filters
                end
                
                def transform( input_uri, output_uri )
                    filter_chain = FilterChain.new
                    @filters.each { |filter| filter_chain.add_filter(filter) }
                    FasterCSV.open( output_uri, mode='a', :col_sep => '|' ) do |csv_writer|
                        output_filter = DumpFileOutputFilter.new( csv_writer )
                        filter_chain.add_filter( output_filter )
                        IO.foreach( input_uri ) do |line|
                            filter_chain.process(line)
                        end
                    end                    
                rescue FilterException, IOError => ex
                    raise TransformError.new( ex ), ( ex.message || $! ), caller
                end
            
            end
        end
    end
end
