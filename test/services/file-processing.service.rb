#!/usr/bin/env ruby

require "rubygems"
require "etl"

include MIS::Workflow

service("etl://fileprocessor/uppercase") do
    sequence(
        Processor.new do |exchange|
            exchange.outbound = Message.new
            exchange.outbound.body = body(exchange).upcase.strip
        end
    )
end

service("etl://fileprocessor/reverse") do
    sequence(
        Processor.new do |exchange|
            exchange.outbound = Message.new
            exchange.outbound.body = body(exchange).reverse.strip
        end
    )
end
