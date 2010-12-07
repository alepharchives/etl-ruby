#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module SQL

            #
            # Acts as a gateway to a postgreSQL database. This facade
            # provides a simplified, yet richer api than either the ruby DBI
            # or native postgres providers (including postgres-pr).
            #
            class Database

                include PostgreSqlAdapter

                #
                # Opens a new (connected) instance and returns it.
                #
                # 'options' := a hash with the following options set
                #       :host => 'host name',
                #       :port => 'port numbwe',
                #       :catalog => 'database name',
                #       :user => 'login name',
                #       :password => 'password'
                def Database.connect( options )
                    #Validation.require_entries_for options, :host, :port, :dbname, :user, :password
                    Database.new( options[ :host ], options[ :port ],
                        options[ :catalog ], options[ :user ], options[ :password ], options[ :disconnected ]
                    )
                end

                def Database.new( *args )
                    if args.size > 5
                        disconnected = args.pop()
                    else
                        disconnected = false
                    end
                    new_instance = super
                    new_instance.connect unless disconnected
                    new_instance.auto_commit_transactions = true
                    new_instance
                end

                # Gets and sets the 'schema' name for the current instance.
                # This is mainly used in sql generation.
                attr_accessor :schema

                initialize_with :host, :port, :catalog, :user, :pass, :attr_reader => true

                # Creates a DatabaseCommand object, initialized with the supplied 'command_text'.
                def create_command command_text
                    DatabaseCommand.new self, command_text
                end

                # Executes the supplied 'command_text' in a command.
                def execute_command command_text
                    #TODO: really, what is point of this "convenience" method!?
                    create_command( command_text ).execute
                end

                # Gets a list of column names for table 'table_name'
                def get_column_metadata( table_name )
                    sql=<<-SQL
                        select column_name
                        from information_schema.columns
                        where
                            table_schema = '#{ @schema || 'public' }' and
                            table_catalog = '#{ @catalog }' and
                            table_name = '#{ table_name }'
                        order by ordinal_position;
                    SQL
                    column_names = []
                    execute( sql.trim_tabs ).each do |record|
                        column_names.push record.column_name
                    end
                    return column_names
                end

                # Gets the number of rows in table 'table_name' This will (obviously)
                # blow up if there is no such table!
                def get_table_rowcount( table_name )
                    return execute_scalar( "select coalesce(count(*), 0) as count from #{table_name};" )
                end

            end

        end
    end
end
