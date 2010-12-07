#!/usr/bin/env ruby

require 'rubygems'

module ETL
    class DeploymentConfiguration

        #
        # connection_string_from_properties( [database_entry='database' ] ) => connection_string
        #
        def connection_string_from_properties( database_entry='database' )
            host, port, catalog, user, password = connection_parameters database_entry
            "postgres://#{host}:#{port}/#{catalog}?user=#{user}&password=#{password}"
        end

        def connection_string_from_hash( hash )
            host = hash[:host]
            port = hash[:port]
            user = hash[:user]
            password = hash[:password]
            catalog = hash[:catalog]
            "postgres://#{host}:#{port}/#{catalog}?user=#{user}&password=#{password}"
        end
        
        alias connection_string connection_string_from_properties

        #
        # connection_parameters( [entry = 'database'] ) => [ 'host', 'port', 'catalog', 'user', 'password' ]
        #
        def connection_parameters( entry='database' )
            [ :host, :port, :catalog, :user, :password ].collect { |name| self.send( entry ).send( name ) }
        end

        #
        # connection_parameters( [entry='database'] ) => { :host=>host, :port=>port, ... etc }
        #
        def connection_properties( entry='database' )
            host, port, catalog, user, password = connection_parameters entry
            return {
                :host => host,
                :port => port,
                :catalog => catalog,
                :user => user,
                :password => password
            }
        end

    end
end
