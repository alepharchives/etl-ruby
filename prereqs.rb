#!/usr/bin/env ruby

=begin rdoc

Loads the pre-requisites required for a successful build. This script is designed
to run against a known, preconfigured environment and doesn't resolve dependencies
remotely.

When called, it will ensure that all gems in the ./gems directory are properly installed,
installing any that are missing (you can see which gems will be loaded by running

    $ gem list --local

on the command line).

Attempts to activate and 'autorequire' all dependencies after installation.

=end

require 'rubygems'
require File.expand_path( File.dirname( __FILE__ ) + '/dependency_loader' )
require 'rake'

gem_directory = 'gems'
#other_os_specific_folder = "#{gem_directory}/#{PLATFORM['mswin'] ? 'unix' : 'win32'}"
#
#puts "excluding #{other_os_specific_folder}"

required_gem_paths = FileList[ "#{gem_directory}/**/*.gem" ].exclude( "#{gem_directory}/rake*", "#{gem_directory}/unix", "#{gem_directory}/win32", "#{gem_directory}/pr" )

load_dependencies( required_gem_paths, force_require=true )

#
# NB: the force_require parameter to load_dependencies won't work for this gem,
#     because the gem <gem-name> statement won't match the gem-autoload behvaiour of dependency_loader
#     without significant modification. We do it by hand here instead.
#
attempts = 1

code=<<-EOF
    ruby -e "require 'rubygems'; require 'postgres';"
EOF
until( system( code ) )
    exit(1) if attempts > 20
    puts "installing postgres-pr (attempt ##{attempts})..."
    attempts += 1
    working_directory = File.dirname( __FILE__ )

    #FileList[ "gems/#{PLATFORM['mswin'] ? 'win32' : 'unix'}/**/*.gem" ]
    required_gem_paths = FileList[ File.expand_path("#{working_directory}/gems/pr/*.gem") ]
    puts required_gem_paths.inspect
    #local_gems = InstalledLocalGems.new

    required_gem_paths.each do |gem_path|
        #installer = PreloadingInstaller.new( gem_path, local_gems, 'postgres-pr' )
        Installer.new( gem_path ).install
    end
end

