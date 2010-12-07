#!/usr/bin/env ruby

require 'rubygems'
require 'uri'
require 'etl/util'

module ETL

    module Integration

        #TODO: nb ...

=begin

    REFACTOR:

        Not sure whether this mixin module is so much use any more => we created it to get around
        the issue of not being able to perform a [ require 'postgres' ] statement on our CI box (because no native
        postgres gems/drivers could be installed), but since we've gone postgres-pr, the lazy initialization is
        less useful (and certainly more complicated).

        Decide in the next few days and either (a) delete this comment and leave the module in or (b) remove/refactor it.

=end

        # I am a mixin, adding data source uri mapping, validation and connection factory behaviour.
        #
        module DataAdapter

            attr_reader :data_source_uri
            attr_accessor :require_scheme

            #todo: find a better way of doing this DI .
            #todo: consider whether it's better to provide a special impl that throws, whenever a driver is unconfigured?
            @@supported_drivers = {}

            @@no_type_mappings_error_message = 'No @@supported_drivers hash has been supplied to the DataAdapter module.'

            def initialize( data_source_uri )
                self.data_source_uri = data_source_uri
            end

            def data_source_uri=( uri_string )
                @data_source_uri = URI.parse( uri_string ) #uri_string.kind_of? String ? URI.parse( uri_string ) : uri_string
            end

            def connection_factory
                #todo: write a test for this next line! whoops!!!!!
                raise InvalidOperationException, @@no_type_mappings_error_message unless @@supported_drivers

                if @require_scheme
                    raise_connectivity_exception unless @data_source_uri.scheme == @require_scheme
                end
                unless @@supported_drivers.has_key? @data_source_uri.scheme.to_sym
                    raise ConnectivityException.new( @data_source_uri, 'no supported driver for this uri' )
                end

                ConnectionFactory.new( @@supported_drivers[ @data_source_uri.scheme.to_sym ] )
            end

            #todo: use a factory to acquire an appropriate connectivity provider and
            #      then move the #connect method on mixers into this module (along with disconnect presumably)

            protected
            def supported_drivers
                @@supported_drivers
            end

            private

            def raise_connectivity_exception
                raise ConnectivityException.new( @data_source_uri )
            end

            class ConnectionFactory
                def initialize( mapping_info )
                    @package_name = mapping_info[ :package_name ]
                    @class_name = mapping_info[ :class_name ]
                    @method_name = mapping_info[ :method_name ]
                end
                def connect( options )
                    begin
                        if @package_name
                            eval "require 'rubygems'; require '#{@package_name.to_s.gsub(/:/mix, '')}'"
                        end
                        method_call_declaration = ""
                        if options
                            if options.kind_of? String
                                method_call_declaration = options
                            else
                                method_call_declaration = "(#{options.inspect})"
                            end
                        end
                        connection = instance_eval "#{@class_name}.#{@method_name}#{method_call_declaration}"
                        return connection
                    rescue
                        raise ConnectivityException.new
                    end
                end
            end

        end

    end
end
