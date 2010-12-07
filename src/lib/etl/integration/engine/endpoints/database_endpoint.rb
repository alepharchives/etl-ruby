#!/usr/bin/env ruby

require 'rubygems'

include MIS::Framework

module ETL
    module Integration
        module Engine
            module Endpoints
                # An endpoint that sits over a database.
                class DatabaseEndpoint < Endpoint
                    
                    def initialize( endpoint_uri, context )
                        validate_arguments( binding() )
                        super(endpoint_uri, context)
                    end
                    
                    def unmarshal()
                        ex = NotImplementedException.new()
                        message = "#{self.class} at [#{self.uri()}] cannot unmarshal exchanges!"
                        _info(message, ex, self)
                        raise ex, message, caller()
                    end

                    def marshal(exchange)
                        super(exchange)
                        unless exchange.inbound.headers.has_key? :command
                            noop_message = Message.new
                            noop_message.set_header(:noop, nil)
                            exchange.outbound = noop_message
                            return nil
                        end
                        # #let's just assume :command => :SQL for now...
                        @processor.process(exchange)
                    end

                    private
                    def resolve_uri( endpoint_uri )
                        unless endpoint_uri.scheme.eql?( 'postgres' )
                            raise ArgumentError, "the 'endpoint uri' must conform to the 'postgres' scheme", caller
                        end
                        @endpoint_uri = endpoint_uri
                        initialize_standby_driver(endpoint_uri)
                    end

                    def initialize_standby_driver(uri)
                        raise ConnectivityException.new if uri.query.nil?
                        match = uri.query.scan( /user=(.*)&password=(.*)/mix )
                        raise ConnectivityException.new( uri, 'driver does not support integrated authentication' ) unless match.size > 0
                        user, password = match[0][0], match[0][1]
                        @database = Database.connect(
                            :host => uri.host,
                            :port => uri.port,
                            :catalog => uri.path.gsub( /\//mix, '' ),
                            :user => user,
                            :password => password,
                            :disconnected => true
                        )
                        @processor = SqlCommandProcessor.new(@database)
                    end

                end
            end
        end
    end
end
