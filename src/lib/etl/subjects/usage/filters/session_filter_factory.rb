#!/usr/bin/env ruby
 
require 'rubygems'
require 'date'

module ETL
    module Subjects
        module Usage
            module Filters
                class SessionFilterFactory < FilterFactory
                    
                    @@changeover_dates = {
                        :sandbox => Date.parse( '2007-09-06' ),
                        :production => Date.parse( '2007-09-05' )
                    }
                    
                    def get_parsing_filter( logfile_date )
                        if @@changeover_dates[ @environment_name ] > logfile_date
                            return get_old_session_parsing_filter
                        else
                            return get_new_session_parsing_filter
                        end
                    end
                    
                    def get_transformation_filter( logfile_date )
                        if @@changeover_dates[ @environment_name ] > logfile_date
                           return OldSessionTransformationFilter.new( @environment_name )
                        else
                            return NewSessionTransformationFilter.new( @environment_name )
                        end
                    end
                    
                    def get_entry_filters( logfile_date )
                        if @@changeover_dates[ @environment_name ] > logfile_date
                            return [ EntryFilter.new( /START INBOUND(.*)(?=makeCall)/ ) ]
                        else
                            return [ EntryFilter.new( /CALL MIS DATA/ ) ]
                        end
                    end
                    
                    private
                    
                    def get_old_session_parsing_filter
                        delimiters = {
                            /\[/ => /\]|$/,
                            /[\w\.]*(?=\(\[)/ => /[^\]]*\]\)/
                        }
                        return create_session_parsing_filter( 'old', delimiters )
                    end
                    
                    def get_new_session_parsing_filter
                        delimiters = { /\[/, /\]|$/ }
                        return create_session_parsing_filter( 'new', delimiters )
                    end
                    
                    def create_session_parsing_filter( type_name, delimiters )
                        transition_tables = eval ::IO.read( 
                            File.join( $config.parser_grammar_definitions_dir, "#{type_name}_session_parsing_filter.grammar" ) )
                        grammar = Grammar.create( :start, transition_tables )
                        parser = Parser.new(
                            grammar,
                            :custom_delimiters => delimiters
                        )
                        parser.name = "#{type_name} session parser"
                        return ParsingFilter.new( parser )                        
                    end
               
                end
            end
        end
    end
end
