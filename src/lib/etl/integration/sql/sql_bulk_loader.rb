#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module SQL
            class SqlBulkLoader

                include Validation
                include DataAdapter

                def initialize( uri_string )
                    super
                    #self.require_scheme 'postgres'
                end

                def load( options )
                    connect
                    sql = copy_statement_for options
                    begin
                        @connection.execute_command sql
                    rescue Exception => sqlEx
                        raise DataAccessException.new( sqlEx.message, sqlEx )
                    ensure
                        @connection.close unless @connection.nil?
                    end
                end

                private
                def copy_statement_for( options )

                    ############################################################################
                    #todo: rename mapping_rules to mapping or vice versa accross all components
                    ############################################################################

                    require_entries_for options, :file_uri, :delimiter, :mapping_rules

                    mapping = options[ :mapping_rules ]
                    require_entries_for mapping, :table, :columns

                    schema_reference = mapping.has_key?( :schema ) ? "\"#{mapping[ :schema ]}\"." : ''

                    #todo: sort this mess out!
                    copy_statement =<<-EOF
                        COPY #{schema_reference}"#{mapping[:table]}" (
                            #{mapping[:columns].join( ',' )}
                        )
                        FROM '#{options[:file_uri]}'
                        WITH DELIMITER AS '#{options[:delimiter]}'
                        NULL AS 'NULL';
                    EOF
                    copy_statement.trim_lines
                end

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
                        raise ConnectivityException.new( data_source_uri, $!, sqlEx ), $!, caller
                    end
                end

            end
        end
    end
end
