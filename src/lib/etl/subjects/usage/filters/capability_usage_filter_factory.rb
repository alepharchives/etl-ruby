#!/usr/bin/env ruby
 
require 'rubygems'
require 'date'

module ETL
    module Subjects
        module Usage
            module Filters
                class CapabilityUsageFilterFactory < FilterFactory
                                       
                    def get_parsing_filter( logfile_date=nil )
                        return ( @parsing_filter_instance ||= create_parsing_filter )
                    end
                    
                    def get_transformation_filter( logfile_date=nil )
                        UsageTransformationFilter.new( @environment_name )
                    end
                    
                    def get_entry_filters( logfile_date=nil )
                        entry_filter = EntryFilter.new( /END INBOUND/ )
                        deprecated_service_filter = EntryFilter.new( /ContactsAvailabilityInterface/, :negate => true )
                        return [ entry_filter, deprecated_service_filter ]
                    end
                    
                    private
                    
                    def create_parsing_filter
                        transition_tables = eval ::IO.read( 
                            File.join( $config.parser_grammar_definitions_dir, "usage_parsing_filter.grammar" ) )
                        grammar = Grammar.create( :start, transition_tables )
                        parser = Parser.new(
                            grammar,
                            :custom_delimiters => { /\[/, /\]|$/ }
                        )
                        parser.name = 'capability usage parser'
                        return ParsingFilter.new( parser )                             
                    end
                end
            end
        end
    end
end
