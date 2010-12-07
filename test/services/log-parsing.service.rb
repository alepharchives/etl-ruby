#!/usr/bin/env ruby

require "rubygems"
require "etl"

include MIS::Workflow

deadLetters = DeadLetterChannel.new()
processor = Processor.new do |exchange|
    begin
        puts "got exchange from #{origin( exchange )}"
        puts "env = #{inheader( :environment )}"
        puts "basename = #{inheader( :basename )}"
    rescue Exception => boom
        puts "something went badly wrong! #{boom.inspect}"
        puts boom.backtrace
    end                    
end

pipeline("etl://pipeline1").from("lfs:/#{context.properties.prebuilt}/"
#    filter("lfs:/#{context.properties.prebuilt}/") do
#        accept(where(header(:basename).matches(/sandbox|production/i)))
#    end
).via(set_header(:environment=>header(:basename))).to(
    splitter(
        service("etl://anything") do
            sequence(
                redirect {
                    where(header(:basename).equals('logs')).
                        via(processor).to(deadLetters)
                }
            )
        end
    )
)
