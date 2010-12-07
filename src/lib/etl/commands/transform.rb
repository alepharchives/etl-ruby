#!/usr/bin/env ruby

require 'rubygems'

include FileUtils
include ETL
include ETL::Commands
include ETL::Commands::FileSystem
#include ETL::Extractors
include ETL::Transformation

module ETL
    module Commands
        module Transformation

            class LdifTrasformCommand < Command

                include IOCommand

                attr_reader :environment

                def initialize( source, destination, environment )
                    super source, destination
                    @environment = environment
                end

                def perform_execute( options={ :mapping => [ :first ] } )
                    extraction_handler = LdifExtractor.new source, environment
                    extraction_handler.extract
                    transformation_handler = ObjectToCsvFileTransform.new destination, '|'
                    transformation_handler.transform extraction_handler.dataset, options
                end

            end

            #class LogTransformCommand < Command
            #
            #    include IOCommand
            #    include ClasspathResolver
            #
            #    attr_reader :environment
            #
            #    def initialize( source, destination, environment, process_type='capability_usage', index=0 )
            #        # REFACTOR: duplication!?
            #        super source, destination
            #        @environment = environment
            #        @process_type = process_type
            #        @index = index
            #    end
            #
            #    def perform_execute
            #        if source.kind_of? Array
            #            source.each do |source_path|
            #              do_execute source_path
            #              @index = @index + 1
            #            end
            #        else
            #            do_execute source
            #        end
            #    end
            #
            #    private
            #    def do_execute( source_path )
            #        initialization_args = [
            #            environment,
            #            source_path,
            #            destination,
            #            @process_type,
            #            @index
            #        ]
            #        transformer = JavaLogFilePipelineTransform.send( :new, *initialization_args )
            #        transformer.transform
            #    end
            #
            #end

        end
    end
end
