#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Subjects
        module Usage
            module Filters
                #TODO: consider whether it is worth pulling this module up so cost and revenue can make use of it!?

                module TransformationFilterSupport

                    include Validation

                    def strip_square_brackets( input )
                        coalesce_null( input.gsub( /[\[\]]/, '' ) )
                    end

                    def coalesce_null( input )
                        coalesce_empty( input, 'NULL' )
                    end

                    def extract_endpoint_kind( input )
                        result = nil
                        if (input[0,4].downcase == 'tel:')
                            result = 'tel'
                        elsif (input[0,4].downcase == 'sip:')
                            result = 'sip'
                        elsif (input.include?('@'))
                            result = 'sip'
                        elsif (input.match(/^\+?\d+/))
                            result = 'tel'
                        end
                        coalesce_null( result )
                    end

                    def extract_service_invocation_time( input )
                        match = ( input || '' ).match( /([\d\:]+)(?:,{1}[\d]{0,3})/ )
                        coalesce_null( match[1] )
                    end
                    
                    def strip_stupid_characters_from_endpoint_uri( input )
                        coalesce_null( input ).gsub( /\|/, "\\|" )
                    end

                    def transform_input_states( states )
                        @transformer.collect( states )
                    end

                    def parse_date(result)
                        if result.nil? or result[1].empty?
                            result = ''
                        else
                            result = Date.parse(result[1].strip)
                        end    
                    end
                    
                    
                    def filter( input, filter_chain )
                        result = transform_input_states(input)
                        result.push @environment
                        filter_chain.proceed( result )
                    rescue StandardError => err
                        raise FilterException.new(
                            err.message,
                            self,
                            input,
                            err
                        ), ( err.respond_to? :message ) ? err.message : $!, caller
                    end
                    
                    def return_null_if_nil_result (result, position)
                        if result.nil?
                            'NULL'
                        else
                            coalesce_null( result[position] ) 
                        end
                    end
                end

            end
        end
    end
end
