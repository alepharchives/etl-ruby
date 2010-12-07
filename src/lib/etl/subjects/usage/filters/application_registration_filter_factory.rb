#!/usr/bin/env ruby
 
require 'rubygems'
require 'date'

module ETL
    module Subjects
        module Usage
            module Filters
                class ApplicationRegistrationFilterFactory < FilterFactory
                    
                    def get_entry_filters( date=nil )
                        return [ EntryFilter.new( /START INBOUND: x.xx.security.applicationreg.ApplicationRegistrationInterface.(enableApplication|disableApplication|createCertificateForApplication|deleteApplication)/ ) ]
                    end                    
                    
                    def get_transformation_filter( log_date=nil )
                        ApplicationRegistrationTransformationFilter.new( @environment_name )
                    end
                    
                    def create_parsing_filter
                        transition_tables = eval ::IO.read( 
                            File.join( $config.parser_grammar_definitions_dir, "application_registration_parsing_filter.grammar" ) )
                        grammar = Grammar.create( :start, transition_tables )
                        parser = Parser.new(
                            grammar,
                             :custom_delimiters => {/(\w+\.)+\w+\(/, /\)$|$|\]\)/, /\[/, /\]/ }
                        )
                        parser.name = 'application registration parser'
                        return ParsingFilter.new( parser )                             
                    end
                end
            end
        end
    end
end
