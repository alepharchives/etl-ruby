#!/usr/bin/env ruby

require 'rubygems'

#TODO: move this over into the parsing api instead!

module ETL
    module Integration
        module Extraction
            LdifEntry = Struct.new( "LdifEntry", :uid, :mail, :cn, :member, :applicationEnabled, :disableReason, :environment )

            class LdifExtractor

                attr_reader :dataset

                def initialize( file_uri, environment='Sandbox' )
                    @file_uri = file_uri
                    @environment = environment
                    raise InvalidOperationException  unless File.file? @file_uri
                    @dataset = []
                end

                def extract
                    @lines = File.readlines( @file_uri )
                    while line = @lines.shift
                        parse_line line if line =~ /# urn/
                    end
                    @dataset.freeze
                end

                def parse_line line
                    entry_lines = []
                    entry_lines.push @lines.shift until @lines.second =~ /^# / or @lines.empty?
                    entry_fields = []
                    entry_lines.each do |entry|
                        [ 'mail', 'cn', 'member', 'uid', 'applicationEnabled', 'disableReason' ].each do |interesting_thing|
                            entry_fields.push entry if entry.starts_with? "#{interesting_thing}: "
                        end
                    end
                    ldif_entry = LdifEntry.new
                    ldif_entry.environment = @environment
                    entry_fields.each do |field|
                        match = field.scan( /(mail|cn|member|uid|applicationEnabled|disableReason):\s{1}(.*)/mix )
                        #todo: consider this error handling policy and whether or not it is correct (and also if it should live here!)...
                        raise Excpetion, "no match on #{field}!'" unless match
                        field_name = match.first[0]
                        field_value = match.first[1]
                        field_value.chomp! unless field_value.nil?
                        ldif_entry.send( "#{field_name}=".to_sym, field_value )
                    end
                    @dataset.push ldif_entry
                end
                
            end
        end
    end
end
