#!/usr/bin/env ruby

require 'rubygems'

include ETL

module ETL
    module Commands

        class DatabaseTransformCommand < Command

            def initialize( source_table, destination_table )
                super
            end

            protected

            def perform_execute( *args )
                database_driver = Database.connect $config.connection_properties
                database_driver.exec( *args )
            end

        end

    end
end
