#!/usr/bin/env ruby

require "rubygems"
require "etl"

include MIS::Workflow

load( './logfile-processor' )

pipeline("etl://logfile-pipeline").from(
    filter("lfs:/#{context().config.prebuilt}/logs") do
        accept(where(header(:scheme).equals('file')))
    end
).to(listener("etl://logfile-processor"))


#service("etl://fileprocessor/uppercase") do
#service("etl://fileprocessor/reverse") do
