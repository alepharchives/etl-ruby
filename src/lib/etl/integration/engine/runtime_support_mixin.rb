#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module RuntimeSupportMixin
                # Tries to determine the origin of an exchange
                def origin(exchange)
                    if exchange.nil?
                        uri = nil
                    else
                        channel = if exchange.inbound.nil?
                            exchange.outbound
                        else
                            exchange.inbound
                        end
                        if channel.nil?
                            uri = nil
                        else
                            uri = channel.headers[:uri]
                        end
                    end
                    if uri.nil?
                        return "Origin Unknown."
                    else
                        return uri.to_s
                    end
                end
            end
        end
    end
end
