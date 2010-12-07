#!/usr/bin/env ruby

require "rubygems"
require "etl"

include MIS::Workflow

load( './file-processing' )

class ExplodingFaultChannel
    def marshal(exchange)
        inheaders = exchange.inbound.headers
        outheaders = exchange.outbound.headers
        message = "Fault encountered on exchange, where input channel originates from " + inheaders[:origin] +
            " and specifies path #{inheaders[:uri]}, and outbound channel originates from #{outheaders[:uri]}}"
        _debug(message)
        raise ExecutionException.new(exchange.context()), exchange.inspect, caller()
    end
end

default_fault_channel(ExplodingFaultChannel.new)

consumer("etl://logfile-processor").via(
    process("etl://fileprocessor/uppercase"),
    process("etl://fileprocessor/reverse")
).to("file://#{context().config.dump_dir}/processed.dump")
