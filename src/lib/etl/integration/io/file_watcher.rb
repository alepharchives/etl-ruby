#!/usr/bin/env ruby
require 'rubygems'
require 'filesystemwatcher'

module ETL
    module Integration
        module IO
            class FileWatcher
                attr_reader :directory, :sleep_time

                def initialize directory, sleep_time = 10
                    raise ArgumentError, sprintf("%s is not a valid directory", directory), caller unless directory && File.directory?(directory)
                    @directory = directory
                    @sleep_time = sleep_time.to_i < 1 ? 10 : sleep_time
                end

                def start
                    @watcher = FileSystemWatcher.new
                    @watcher.addDirectory(@directory)
                    @watcher.sleepTime = @sleep_time
                    @watcher.start do |status, file|
                        case status
                        when FileSystemWatcher::CREATED
                            @on_create.call file unless @on_create.nil?
                        when FileSystemWatcher::MODIFIED
                            @on_modify.call file unless @on_modify.nil?
                        else
                            printf("Unmatched status: %s", status)
                        end
                    end
                end

                def join
                    @watcher.join
                end

                def stop
                    @watcher.stop
                end

                def on_created &block
                    @on_create = block
                end

                def on_modified &block
                    @on_modify = block
                end
            end
        end
    end
end
