#!/usr/bin/env ruby

require 'rubygems'

include ETL::Integration

module ETL
    module Integration
        module Extraction
            class SqlExtractor

                include Validation
                include DataAdapter #adds connector behaviour

                attr_reader :dataset

                def initialize( uri_string )
                    super
                    @dataset = []
                    @connection = nil
                end

                def extract( options )
                    require_entries_for options, :environment, :schema, :source_table
                    sql = build_statement_for options

                    begin
			connect
                        command = @connection.create_command sql
                        @dataset = command.execute
                    ensure
                        disconnect
                    end
                end

                private

                def build_statement_for options
		    if options.has_key?(:columns)
			columns = options[:columns].join( ", " )
		    else
			columns = "*"
                    end
                    select_sql = %(select #{columns}, '#{options[:environment]}' as environment from "#{options[:schema]}"."#{options[:source_table]}")

                    if options.has_key? :join
                        select_sql << " #{options[:join]}"
                    end    
                        
                    criteria =
                    if options.has_key? :criteria
                        "where #{options[:criteria]}"
                    else
                        ''
                    end
                    unless criteria.size == 0
                        return sprintf( "%s %s;", select_sql, criteria )
                    end
                    return sprintf( "%s;", select_sql )
                end

                #REFACTOR: this duplicates the BULK LOAD (and date dimension) code => extract a superclass quick!!!!

                def connect
                    raise ConnectivityException.new if data_source_uri.query.nil?
                    match = data_source_uri.query.scan( /user=(.*)&password=(.*)/mix )
                    raise ConnectivityException.new( data_source_uri, 'driver does not support integrated authentication' ) unless match.size > 0
                    user, password = match[0][0], match[0][1]
                    begin
                        @connection = connection_factory.connect(
                            :host => data_source_uri.host,
                            :port => data_source_uri.port,
                            :catalog => data_source_uri.path.gsub( /\//mix, '' ),
                            :user => user,
                            :password => password
                        )
                    rescue Exception => sqlEx
                        raise ConnectivityException, $!
                    end
                end

                def disconnect
                    #note: is there a better way? it isn't *closable*...
                    @connection.close unless @connection.nil?
                end
            end
        end
    end
end
