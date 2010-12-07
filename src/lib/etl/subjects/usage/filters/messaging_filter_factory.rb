#!/usr/bin/env ruby
 
require 'rubygems'
require 'date'

module ETL
    module Subjects
        module Usage
            module Filters
                class MessagingFilterFactory < FilterFactory
               
                    @@changeover_date = Date.parse( '2007-09-05' )
                    
                    def get_entry_filters( date=nil )
                        if !date.nil? && date <= @@changeover_date
                            return [ EntryFilter.new( /START OUTBOUND: com.xx.capabilities.(messaging|sms).SmsClient.sendToPlatform/ ) ]
                        end
                        return [ EntryFilter.new( /continueSendMessage\(recipients/ ) ]
                    end                    
                    
                    def get_transformation_filter( log_date=nil )
                        MessagingTransformationFilter.new( @environment_name )
                    end
                    
                    def create_parsing_filter
                        transition_tables = eval ::IO.read( 
                            File.join( $config.parser_grammar_definitions_dir, "messaging_parsing_filter.grammar" ) )
                        grammar = Grammar.create( :start, transition_tables )
                        parser = Parser.new(
                            grammar,
                            :custom_delimiters => { /(\w+\.)+\w+\(/, /\)$|$|\]\)/, /\w+\(/, /\)$|$/, /\[/, /\]/ }
                        )
                        parser.name = 'messaging parser'
                        return ParsingFilter.new( parser )                             
                    end
                end
            end
        end
    end
end
