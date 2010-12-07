#!/usr/bin/env ruby

require 'rubygems'
require File.expand_path( File.dirname( __FILE__ ) + '/util' )
require 'singleton'
require 'yaml'

module ETL

    #TODO: move this sort of thing (e.g. object extensions) into a more appropraite module.
    #TODO: put a yaml wrapper around this one.
    class DeploymentConfiguration

        private

        @@instance = DeploymentConfiguration.new

        public

        def DeploymentConfiguration.instance
            @@instance
        end

        def respond_to?( method_name )
            super ? true : yaml.respond_to?( method_name )
        end

        def initialize( file_uri=nil )
            raise ArgumentError, 'invalid file uri' unless file_uri.nil? or File.file? file_uri
            @base_uri = file_uri
            @config = nil
        end

        protected

        def method_missing( method_name, *args )
            config = yaml
            return_value = config.send( method_name, *args ) rescue super
            #just assume that people are going to use config to store relative paths...
            return File.resolve_path( return_value ) if return_value.starts_with? '~' rescue StandardError
            return_value
        end

        private

        def base_uri
            return @base_uri unless @base_uri.nil?
            '~/config.yaml' #default
        end

        def yaml
            load_config if @config.nil?
            @config
        rescue
            raise InvalidOperationException, $!
        end

        def load_config
            hash = YAML.load File.open( File.resolve_path( base_uri ) )
            make_hash_callable hash
            @config = hash
        end

    end

end

#[ 'deployment', 'config', 'properties', 'settings' ].collect! do |global_variable_name|
#    eval "$#{global_variable_name}  = ETL::DeploymentConfiguration.instance"
#end

$config = ETL::DeploymentConfiguration.instance
