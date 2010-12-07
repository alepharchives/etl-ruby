#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Container
                # Occurs when an attempt to dynamically load a class fails at runtime.
                class ClassLoadException < ExecutionException
                    attr_reader :class_file
                    def initialize(class_file, message=$!, cause=$ERROR_INFO)
                        @class_file = class_file
                        @message = message
                    end
                end
            end
        end
    end
end
