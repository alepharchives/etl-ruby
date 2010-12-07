#!/usr/bin/env ruby

require "rubygems"
require "etl"

include MIS::Workflow

#load("./ldif-consumer")

class LdifTransformer < Processor
    def do_process(exchange)
        destination = destination_endpoint()
        _debug("Attempting transformation targetting uri [#{destination}].")
        transormer = ObjectToCsvFileTransform.new(
            destination,
            inheader(:delimiter)
        )
    end

    private
    def destination_endpoint()
        return context.lookup_uri(
            "#{context.properties.dump_dir}#{File::Separator}#{inheader(:environment).lcase}.ldap.dump"
        )
    rescue Exception => ex
        _debug(ex.message, ex)
    end
end

_debug("Creating ldif-processing service")
processing_service = service("etl://ldif-processing") do
    sequence(
        extractor = (
            Processor.new(:delimiter => '|') do |exchange|
                extractor = LdifExtractor.new(header(:basename), environment())
                extractor.extract()
                exchange.outbound = msg=Message.new
                msg.body = extractor.dataset
            end
        ),
        LdifTransformer.new()
    )
end

_debug("Creating ldif-consumer pipeline")

#TODO: I think the filter is screwing around with the granularity conversion somehow!?

consumer = consumer("etl://ldif-consumer").to(
    filter(processing_service) { accept(where(scheme.equals('file') & header(:basename).matches(/\.ldif/i))) }
)

_debug("Creating ldif-pipeline")
pipeline("etl://ldif-pipeline").from(
    filter("lfs:/#{context.config.landing_dir}/prebuilt/ldap/") do
        accept(where(scheme.equals('lfs')))
    end
).via(set_header(:environment => header(:basename))).to(consumer)
