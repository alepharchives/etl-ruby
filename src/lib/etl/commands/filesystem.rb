#!/usr/bin/env ruby

require 'rubygems'
require 'fileutils'

include FileUtils

module ETL
    module Commands
        module FileSystem

            module IOCommand

                include Validation

                public

                attr_reader :source, :destination

                #
                # Gets a copy of the opt-hash for this instance.
                #
                # NB: Because this is a copy, any changes made will be ignored.
                #
                def options
                    Hash[ @options ]
                end

                protected

                def initialize( source, destination, options={} )
                    raise ArgumentError if missing? source, destination

                    if source.kind_of? Array
                        options[:content_only] = false
                        source.each { |element| validate_uri element }
                    else
                        validate_uri source
                        source = File.join source, '.' if options[:content_only]
                    end
                    validate_uri destination

                    @source = source
                    @destination = destination
                    @options = options
                end

                def validate_uri uri
                    raise ArgumentError, invalid_uri( uri ), caller unless File.file? uri or File.directory? uri
                end

                private

                def invalid_uri uri
                    "Uri #{uri} does not map to a file or directory."
                end

            end

            #
            # Performs cp operations on files and/or directories.
            #
            class CopyCommand < Command

                include IOCommand

                #
                # Initializes a CopyCommand instance
                #
                # 'source' => the source folder or file, or an array of file names
                # 'destination' => the destination folder (or file, although it's a pointless distinction
                #               as far as the command object is concerned).
                # 'options' => a hash containing the following options:
                #
                # :content_only => copy on the content of the source folder, not the folder itself (this
                #           option is ignored unless 'source' is a directory).
                #
                def initialize source, destination, options={}
                    super
                end

                #
                # Execute the command.
                #
                def perform_execute
                    cp_r @source, @destination, :verbose => true
                end

            end

            #
            # Performs cp operations on files and/or directories.
            #
            class MoveCommand < Command

                include IOCommand

                #
                # Initializes a MoveCommand instance
                #
                # 'source' => the source folder or file, or an array of file names
                # 'destination' => the destination folder (or file, although it's a pointless distinction
                #               as far as the command object is concerned).
                # 'options' => a hash containing the following options:
                #
                # :content_only => copy on the content of the source folder, not the folder itself (this
                #           option is ignored unless 'source' is a directory).
                #
                def initialize source, destination, options={}
                    super
                end

                #
                # Execute the command.
                #
                def perform_execute
                    mv @source, @destination, :verbose => true
                end

            end

        end
    end
end
