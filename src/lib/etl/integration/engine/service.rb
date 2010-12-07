#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            # Abstracts a series of sequential processing steps into a service.
            class Service < Endpoint

                include Validation

                attr_reader :processors

                #TODO: pass the bloody context as well!

                def initialize(uri, context, *processors)
                    super(uri, context)
                    raise ArgumentError, 'a  processor cannot be nil', caller if processors.include? nil
                    raise StandardError, "Aha!", caller() if processors.detect { |item| item.kind_of?(Array) }
                    @processors = processors
                    @fault_channel = context.default_fault_channel.nil? ? DefaultErrorChannel.new : context.default_fault_channel
                end

                # Gets the fault channel for this instance.
                def fault_channel
                    #TODO: fetch this lazily each time from the context...
                    @fault_channel
                end

                # Sets the fault channel for this instance.
                attr_writer :fault_channel

                # Marshals the supplied exchange into this endpoint for processing.
                def marshal(exchange)
                    if exchange.inbound.nil?
                        raise InvalidPayloadException.new(context(), exchange, "No inbound channel supplied.")
                    end
                    last_exchange = do_process(exchange.copy())
                    last_exchange.copy_response_to(exchange)
                end

                private

                def do_process(exchange)
                    _debug("Attempting to process exchange from [#{origin(exchange)}].")
                    if @processors.empty?
                        response = exchange.reverse()
                        response.outbound.set_header(:noop, nil)
                        return response
                    end
                    last_exchange = exchange
                    @processors.each_with_index do |processor, index|
                        processor.process(last_exchange)
                        fault_channel.marshal(last_exchange) if last_exchange.has_fault?
                        last_exchange = last_exchange.flip() unless index.eql?(@processors.size - 1)
                    end
                    last_exchange
                end

                protected

                def resolve_uri(uri)
                    uri = URI.parse(uri) if uri.kind_of? String
                    raise UnresolvableUriException.new(uri) unless uri.scheme.eql?("etl")
                end

            end
        end
    end
end
