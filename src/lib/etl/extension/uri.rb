#!/usr/bin/env ruby

require "rubygems"

module URI

    class << self
        alias original_parse parse

        #
        # == Synopsis
        #
        #   URI::parse(uri_str)
        #
        # == Args
        #
        # +uri_str+::
        #   String with URI.
        #
        # == Description
        #
        # Creates one of the URI's subclasses instance from the string.
        #
        # == Raises
        #
        # URI::InvalidURIError
        #   Raised if URI given is not a correct one.
        #
        # == Usage
        #
        #   require 'uri'
        #
        #   uri = URI.parse("lfs://usr/bin/local")
        #   p uri
        #   # => #<URI::LFS:0x202281be URL:lfs://usr/bin/local>
        #   p uri.scheme
        #   # => "lfs"
        #   p uri.drive
        #   # => nil
        #   p uri.path
        #   # => "/usr/bin/local"
        #
        def parse(uristring)
            return original_parse(uristring) unless uristring[/lfs\:/i]
            escaped = self.escape(uristring)
            if result = escaped[/(?:lfs:\/[\/]{1})/i]
                return LFS.new('', escaped - result)
            else
                match = escaped.match(/lfs:\/([\w\d%\4-_\.\!\~\*\'\(\)\\]+)\/(.*)/i)
                if match
                    drive = match[1]
                    path = match[2]
                    uristring = "lfs://#{drive}/#{path}"
                end
            end
            scheme, userinfo, host, port,
                registry, path, opaque, query, fragment = self.split(uristring)
            return LFS.new(host, path)
        end
    end

#      pchar         = unreserved | escaped | ":" | "@" | "&" | "=" | "+"
#
#      reserved      = ";" | "/" | "?" | ":" | "@" | "&" | "=" | "+"
#
#      unreserved    = alpha | digit | mark
#
#      mark          = "$" | "-" | "_" | "." | "!" | "~" |
#                           "*" | "'" | "(" | ")" | ","

    # Represents a Local File System entry.
    class LFS < Generic

        include Validation

        attr_reader :drive

        #
        # == Args
        #
        # +drive+::
        #   Optional drive letter - for Windows based systems only.
        #   Defaults to an empty string.
        # +path+::
        #   Path on local server (e.g. localhost). Can be a relative path.
        #
        # == Description
        #
        # Creates a new URI::LFS instance.
        #
        def initialize(drive, path)
            ensure_valid_args(drive, path)
            super(
                'lfs',
                '',
                '',
                port=nil,
                registry=nil,
                URI.escape(path),
                opaque=nil,
                query=nil,
                fragment=nil,
                arg_check = false
            )
            @drive = ( drive.size > 0 ) ? drive : nil
        end

#        prefix = full_path.starts_with?(File::Separator) ? '' : File::Separator 
#                            suffix = full_path.ends_with?(File::Separator) ? '' : File::Separator
#                            full_path = "#{prefix}#{full_path}#{suffix}"
        def full_path
            path = @path
            prefix = path.starts_with?(File::Separator) ? '' : File::Separator 
            suffix = path.ends_with?(File::Separator) ? '' : File::Separator
            if running_on_windows?
                drive = drive_letter_or_host
                drive = "#{drive}:" unless drive.empty?
                return "#{drive}#{prefix}#{path}#{suffix}"
            else
                imagined_host = @drive
                prefix = "#{prefix}#{imagined_host}#{prefix}" unless String.nil_or_empty?(imagined_host)
                return "#{prefix}#{path}#{suffix}"
            end
        end

        def to_s
            return "#{@scheme}:#{File::Separator}#{full_path()}"
        end

        private
        
        def drive_letter_or_host
            return '' if String.nil_or_empty?(@drive)
            result = @drive[/.+(?:[\:\\\/]*)/i]
            return result
        end

        def ensure_valid_args(drive, path)
            validate_arguments(binding())
        end

    end
end
