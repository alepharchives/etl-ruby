# #!/usr/bin/env ruby
 
require 'rubygems'

module ETL
    module Parsing
        class ParserFactory
            
            include Validation
            
            @@parsers = {}
            
            def self.get_parser( grammar_file_uri )
                parser = @@parsers[ grammar_file_uri ]
                if (parser.nil?)
                    grammar_def = eval ::IO.read( grammar_file_uri )
                    transitions = grammar_def[:transitions]
                    delimiters = grammar_def[:delimiters]
                    grammar = Grammar.create( :start, transitions )
                    parser = Parser.new( grammar, :custom_delimiters => delimiters )
                    @@parsers[ grammar_file_uri ] = parser
                end
                return parser
            end            
        end
    end
end
