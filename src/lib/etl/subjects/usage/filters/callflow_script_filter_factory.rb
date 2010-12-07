#!/usr/bin/env ruby
 
require 'rubygems'
require 'date'

module ETL
    module Subjects
        module Usage
            module Filters
                class CallflowScriptFilterFactory < FilterFactory
                    
                    def get_entry_filters( date=nil )
                        return [ EntryFilter.new( /Script Event Type=\(END\)/ ) ]
                    end                    
                    
                    def get_transformation_filter( log_date=nil )
                        CallflowScriptTransformationFilter.new( @environment_name )
                    end
                    
                    def create_parsing_filter
                        transition_tables = eval ::IO.read( 
                            File.join( $config.parser_grammar_definitions_dir, "callflow_script_parsing_filter.grammar" ) )
                        grammar = Grammar.create( :start, transition_tables )
                        parser = Parser.new(
                            grammar,
                            :custom_delimiters => { /\[/, /\]|$/ }
                            #:custom_delimiters => { /(\w+\.)+\w+\(/, /\)$|$|\]\)/, /\w+\(/, /\)$|$/, /\[/, /\]/ }
                        )
                        parser.name = 'callflow script usage parser'
                        return ParsingFilter.new( parser )                             
                    end
                end
            end
        end
    end
end
