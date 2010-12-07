#!/usr/bin/env ruby
 
require 'rubygems'

module ETL
    module Transformation
        module Pipeline
            module Filters
                
                # I am a dynamic proxy/decorator for transformation filters.
                class DecoratorFilter
                    mixin Validation
                    
                    def initialize( target_filter, &filter_block )
                        validate_arguments(binding())
                        raise ArgumentError, "the 'filter block' must have an arity of 3" unless filter_block.arity.eql?( 3 )
                        @filter_block = filter_block
                        @target_filter = target_filter
                    end                    
                    
                    def filter( input, filter_chain )
                        begin
                            @filter_block.call( @target_filter, input, filter_chain )
                        rescue FilterException => fEx
                            raise fEx
                        rescue StandardError => ex
                            wrap_exception( ex, input )
                        end
                    end
                    
                    private 
                    
                    def wrap_exception( ex, input )
                        raise FilterException.new( ( message = ex.message || $! ), self, input, ex ), message, caller
                    end
                    
                end
            end
        end
    end
end
