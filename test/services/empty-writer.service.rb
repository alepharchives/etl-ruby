#!/usr/bin/env ruby

require "rubygems"
require "etl"

include MIS::Workflow

consumer("etl://empty/writer").to("file://#{context().config.dump_dir}/empty.dump").via(
    Processor.new do |exchange|
        exchange.outbound = Message.new
        exchange.outbound.body = exchange.inbound.body.upcase
    end
)
