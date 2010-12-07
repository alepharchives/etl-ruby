##!/usr/bin/env ruby
#
#require 'rubygems'
#
#include ETL
#
#module ETL
#    module Transforms
#        module Pipeline
#            module Filters
#
#                class TransformationFilter
#
#                    initialize_with :transformer, :validate => true
#
#                    def filter( input, filter_chain )
#                        #filter_chain.proceed
#                        result = @transformer.collect( input )
#                        puts result.class
#                        puts result.first.class
#                        puts result.last.class
#                        return result
#                    rescue StandardError => err
#                        raise FilterException.new(
#                            ( msg = ( err.respond_to? :message ) ? err.message : $! ),
#                            err, self, input
#                        ), msg, caller
#                    end
#
#                end
#
#            end
#        end
#    end
#end
