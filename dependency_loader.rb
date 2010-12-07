#!/usr/bin/env ruby

=begin rdoc

Presents an object model for loading dependencies from a known location (e.g. filesystem, remote, etc)
and ensuring that they are installed and ruby 'required' (e.g. loaded via the *gem*, *load* and/or *require* commands).

Requires Rake (>= 0.7.x).

=end

require 'rubygems'
require 'rubygems/installer'
require 'rake'

class GemInstallationInfo
    attr_accessor :gem_name, :long_name, :auto_require

    def gem_file
        @long_name + '.gem'
    end

    def activate
        raise StandardError, 'Invalid gem name' if @gem_name.nil?
        fails_to_load @gem_name unless gem @gem_name
        require @auto_require unless @auto_require.nil?
    end

    def to_s
        "Gem[#{@gem_name} - #{@long_name} (auto require=#{@auto_require})]"
    end
end

class InstalledLocalGems
    def initialize
        @gems = []
        search
    end

    def flush_gem_cache
        Gem::clear_paths
        search
    end

    def search( s_pattern='[\w].*' )
        search_results = Gem::cache.search( s_pattern )
        @gems = search_results.collect do |gem_spec|
            gem_info = GemInstallationInfo.new
            gem_info.gem_name = gem_spec.name
            gem_info.long_name = gem_spec.full_name
            gem_info.auto_require = gem_spec.autorequire
            gem_info
        end
        @gems
    end

    def find( pattern )
        @gems.each do |gem|
            return gem if gem.gem_name == pattern or gem.long_name == pattern or gem.gem_file == pattern
        end
        return nil
    end

    def each
        @gems.each do |gem_info|
            yield gem_info
        end
    end

end

def abort_build( message='Build failed. See errors above.' )
    puts message
    exit(1)
end

def fails_to_load( failed_gem )
    abort_build "Build failed. Unable to load gem(s) #{failed_gem.inspect}."
end

def short_form_of_gem_name( gem_name )
    File.basename gem_name
end

def installed_as_name_for( gem_name )
    gem_name.gsub( /[^\w].*/mix, '' )
end

class DependencyLoader

    #
    # initializes a DependencyLoader instance.
    #
    # 'file_list' := a list of gem files to load.
    # 'force_require' := if true, all loaded gems are auto-required.
    #
    def initialize( file_list, force_require=true )
        @force_require = force_require
        @required_gem_paths = file_list.collect do |file_name|
            File.expand_path( file_name )
        end
        @required_gem_names = @required_gem_paths.collect { |item| File.basename( item ) }
        @local_gems = InstalledLocalGems.new
    end

    #
    # loads all dependencies, installing any missing gems
    #
    def load_dependencies
        @local_gems.each do |gem_info|
            gem_file_name = gem_info.gem_file
            gem_name = installed_as_name_for( short_form_of_gem_name( gem_file_name ) )
            @required_gem_names.delete gem_file_name
        end
        @required_gem_paths.each do |gem_path|
            gem_short_name = short_form_of_gem_name gem_path
            if @required_gem_names.include? gem_short_name
                puts "installing #{gem_path}"
                installer = @force_require ? PreloadingInstaller.new( gem_path, @local_gems ) : Installer.new( gem_path )
                installer.install
            end
        end
    end
end

class Installer

    #
    # creates an Installer instance, for the gem on the supplied 'gem_path'.
    #
    def initialize( gem_path )
        @gem_path = gem_path
    end

    #
    # installs the gem on the path supplied during initialization.
    #
    def install
        automated_install {
            installer = Gem::Installer.new( @gem_path,
                :domain => :both,
                :generate_rdoc => true,
                :generate_ri   => true,
                :force => true,
                :test => false,
                :wrappers => true,
                :install_dir => Gem.dir,
                :security_policy => nil
            )
            installer.install
        }
    end

    protected
    def automated_install
        begin
            yield if block_given?
        rescue
            abort_build "Automated install failed. Try running the command manually (e.g. $ sudo gem install #{@gem_short_name})"
        end
    end

    def gem_short_name
        short_form_of_gem_name @gem_path
    end

end

class PreloadingInstaller < Installer

    #
    # creates an Installer instance, for the gem on the supplied gem_path,
    # using the InstalledLocalGems 'local_gems' to require/gem/load the gem into
    # the calling application.
    #
    def initialize( gem_path, local_gems, override_gem_name=nil )
        super( gem_path )
        @local_gems = local_gems;
        @override_gem_name = override_gem_name
    end

    #
    # installs the gem on the path supplied during initialization.
    #
    def install
        super
        automated_install {
            @local_gems.flush_gem_cache
            gem_name = @override_gem_name.nil? ? installed_as_name_for( self.gem_short_name ) : @override_gem_name
            installed_gem = @local_gems.find( gem_name )
            fails_to_load gem_name if installed_gem.nil?
            installed_gem.activate
        }
    end

end

#
# Loads all the supplied dependencies.
#
# 'file_list' := a list of gem files to load.
# 'force_require' := if true, all loaded gems are auto-required.
#
def load_dependencies( file_list, force_require=true )
    loader = DependencyLoader.new( file_list, force_require )
    loader.load_dependencies
end
