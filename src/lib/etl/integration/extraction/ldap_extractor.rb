#!/usr/bin/env ruby

require 'rubygems'
include ETL::Integration

module ETL
    module Integration
        module Extraction
            class LdapExtractor

                include Validation
                include DataAdapter #adds connector behaviour

                attr_reader :dataset

                def initialize( uri_string )
                    super
                    self.require_scheme = 'ldap'
                    @dataset = []
                    @connection = nil
                end

                def extract( options )
                    require_entries_for options, :treebase, :filter, :attr
                    connect
                    begin
                        @connection.search(
                            :base =>   options[ :treebase ],
                            :filter => options[ :filter ],
                            :attr =>   options[ :attr ],
                            :attrsonly => true
                        ) { |entry| @dataset.push entry }
                    rescue
                        puts $!
                    ensure
                        disconnect
                    end
                end

                private
                def connect
                    auth = {:method => :anonymous} #if data_source_uri.user.nil?
                    begin
                        @connection = connection_factory.connect(
                            :host => data_source_uri.host,
                            :port => data_source_uri.port,
                            :auth => auth
                        )
                    rescue
                        raise ConnectivityException
                    end
                end

                def disconnect
                    #note: is there a better way? it isn't *closable*...
                    @connection = nil
                end
            end
        end
    end
end
