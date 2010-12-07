#!/usr/bin/env ruby

require 'rubygems'
require 'strscan'

include ETL

module ETL
    module Parsing
        class Scanner

            attr_accessor :options

            def initialize( input_string, options={} )
                @scanner = StringScanner.new( input_string )
                @current_token = nil
                @options = options
            end

            def next_token
                until @scanner.eos?
                    @scanner.skip( /[\s]+/ )
                    @current_token = scan_until_end_token
                    return @current_token ||= nil
                end
            end

            def eos?
                @scanner.eos?
            end

            private

            def scan_until_end_token
                if @options.has_key?( :custom_delimiters )
                    @options[ :custom_delimiters ].each do |start_pattern, end_pattern|
                        if @scanner.check( start_pattern )
                            return @scanner.scan_until( end_pattern ).strip
                        end
                    end
                end
                return @scanner.scan_until( /\s|$/ ).strip
            end

        end
    end
end
