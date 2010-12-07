#!/usr/bin/env ruby

require "rubygems"
require "etl"

include MIS::Workflow

consumer = consumer("etl://consumer").to(
    service("etl://service") do
        sequence(
            Processor.new { |exchange| puts "Got an exchange from #{origin(exchange)}." }
        )
    end
)

pipeline("etl://ldif-pipeline").from(
    filter("lfs:/#{context.config.landing_dir}") do
        accept(where(scheme.equals('lfs')))
    end
)
