#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Processors
                # A processor that executed a command.
                # NB: used internally by the container to execute pipelines...
                class CommandProcessor < Processor
                    
                    include Validation
                    
                    def initialize(command)
                        super( :status => :complete )
                        validate_arguments(binding())
                        raise InvalidOperationException.new("A command must respond to 'execute'.") unless command.respond_to? :execute
                        @command = command
                    end
                    
                    protected
                    def do_process(exchange)
                        @command.execute()
                    end
                    
                end
            end
        end
    end
end
