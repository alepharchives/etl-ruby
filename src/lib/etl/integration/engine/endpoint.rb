#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            # Implements the message-endpoint integration pattern
            # (applied to data-integration in our case).
            class Endpoint

                include Validation
                include ETL::Integration::Engine::RuntimeSupportMixin

                # Gets the context that created this instance.
                attr_reader :context


                # Gets the uri for the current instance.
                def uri()
                    return @endpoint_uri
                end

                def initialize( endpoint_uri, execution_context )
                    validate_arguments(binding)
                    endpoint_uri = URI.parse( endpoint_uri ) if endpoint_uri.kind_of? String
                    resolve_uri( endpoint_uri )
                    @endpoint_uri = endpoint_uri
                    @context = execution_context
                end

                # Unmarshals the next message exchange from this endpoint.
                # Clients can repeatedly call this method to consume
                # multiple exchanges until it returns 'nil', which indicates
                # that the endpoint has finished producing.
                #
                def unmarshal()
                    _info("Unmarshalling from #{self.class} at [#{self.uri()}].")
                end

                # Marshalls the supplied exchange to this endpoint.
                # The semantics of marshalling vary according to the type of endpoint
                # and the content(s) of the inbound message in the supplied exchange.
                #
                # For further details, see #ETL::Integration::Engine::Exchange
                #
                def marshal(exchange)
                    _info("#{self.class} at [#{self.uri()}] recieved exchange from [#{origin(exchange)}].", nil, self)
                end

                protected
                def build_outbound_exchange( scheme, path )
                    origin = @endpoint_uri.dup
                    root = origin.to_s
                    root = root[0..root.size - 2] if root.ends_with? '/'
                    uri = URI.parse("#{root}/#{path.sub('/', '')}")
                    uri.scheme = scheme
                    host = (uri.host.nil?) ? '' : "#{uri.host}"
                    message = Message.new
                    message.set_header( :origin, origin )
                    message.set_header( :uri, uri )
                    message.set_header( :basename, basename(uri.path) )
                    message.set_header( :scheme, uri.scheme )
                    message.set_header( :path, "/#{host}#{uri.path}" )
                    message.set_header( :query, uri.query ) unless uri.query.nil?
                    exchange = Exchange.new(@context)
                    exchange.outbound = message
                    return exchange
                end

            end
        end
    end
end
