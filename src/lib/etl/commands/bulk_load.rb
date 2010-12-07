#!/usr/bin/env ruby

require 'rubygems'
require File.dirname( __FILE__ ) + '/filesystem'

include ETL
include ETL::Commands
include ETL::Commands::FileSystem
#include ETL::Loaders # for SqlBulkLoader

module ETL
    module Commands

        class BulkLoadCommand < Command

            def initialize( source, destination )
                super
            end

            protected

            def perform_execute( *args )
                #raise ArgumentError, 'invalid option(s) hash', caller unless args.first.kind_of?( Hash )
                loader = SqlBulkLoader.new $config.connection_string
                loader.load( *args )
            end

        end

    end

end
