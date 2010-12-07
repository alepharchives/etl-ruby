#!/usr/bin/env ruby

require 'rubygems'

#TODO: move the i/o stuff into the integration package(s)...

module PathResolver

    #
    # File.resolve_path( path ) => somePathString
    # Attempts to resolve 'path' (which is presumably relative!?) to a
    # real path (e.g. file or directory).
    #
    # If an environment variable 'STARTUP_PATH' is set, will attempt to join
    # 'path' on to this and resolve. If this fails, will try the working directory,
    # the dirname of global $PROGRAM_NAME and finally (if all else fails), will
    # iterate the directories in the global $LOAD_PATH attempting to join with them.
    #
    # Raises StandardError unless 'path' is already a valid path; OR, is prefixed by a
    # tilde (~) and/or starts with the path separator character (File::SEPARATOR).
    #
    def resolve_path( path )

        #REFACTOR: this is an obvious place to use chain of responsibility

        unless path.starts_with? '~' or path.starts_with? File::SEPARATOR
            expanded = File.expand_path( path )
            return expanded if File.valid_path? expanded
        end
        message = "Invalid relative path #{path}. Prefix with '~' or '#{File::SEPARATOR}' and try again."
        raise StandardError, message, caller unless path.starts_with? '~' or path.starts_with? File::SEPARATOR

        path = path[1..path.size - 1] if path.starts_with? '~'
        return path if valid_path? path

        return File.expand_path( File.join( ENV['STARTUP_PATH'], path ) ) if ENV['STARTUP_PATH']

        abspath = File.expand_path File.join( Dir.getwd, path )
        return abspath if valid_path? abspath

        abspath = File.expand_path( path )
        return abspath if valid_path? abspath

        abspath = File.expand_path File.join( File.dirname( $PROGRAM_NAME ), path )
        return abspath if valid_path? abspath

        $LOAD_PATH.each do |dir|
            location = File.expand_path File.join( dir, path )
            if valid_path? location
                return location
            end
        end
        raise StandardError, "Unable to resolve path #{path}", caller
    end

    def valid_path? path
        File.directory? path or File.file? path
    end

end

class Path
    include PathResolver

    @@resolvable_method_names = [
        :exist?,
        :file?,
        :directory?,
        :basename,
        :delete,
        :ftype,
        :mtime,
        :new,
        :open,
        :size,
        :split
    ]

    def method_missing( method_name, *args )
        return super unless @@resolvable_method_names.include? method_name
        args.unshift @path unless args.include? @path
        File.send( method_name, *args )
    end

    def initialize( uri )
        @path = uri
    end

    def dirname
        return @path if self.directory?
        return File.dirname( @path )
    end

    def resolve!( uri )
        uri = uri.to_s
        if uri.include? '..'
            uri = '/' + uri if uri.starts_with? '..'
            @path = File.expand_path( File.join( @path, uri ) )
        else
            @path = resolve_path File.join( @path, uri )
        end
    end

    def expand!( ignored=nil ) #:nodoc:
        @path = File.expand_path @path
    end

    def join!( uri )
        @path = File.join( @path, uri.to_s )
    end

    [ :resolve, :expand, :join ].each do |method_name|
        class_eval(<<-CODE
            def #{method_name.to_s}( uri=nil ) #:nodoc:
                replacement = Path.new @path
                replacement.#{method_name.to_s}! uri
                return replacement
            end
        CODE
        )
    end

    def to_s
        @path
    end

end

class File
    extend PathResolver
end