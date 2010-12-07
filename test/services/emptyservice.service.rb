#!/usr/bin/env ruby

require "rubygems"
require "etl"

include MIS::Workflow

load( File.dirname(__FILE__) + "/empty-writer" )
#this path is equivalent to './empty-writer'

service("etl://empty") do
    sequence(
        Processor.new do |exchange|
            exchange.outbound = Message.new
            exchange.outbound.body = "empty"
        end,
        process("etl://empty/writer")
    )
end
