#!/usr/bin/env ruby
 
require 'rubygems'

module ETL
    module Integration
        module Engine
            module Channels
                    
                #
                # This is the default error channel when no custom error channel is provided.
                #
                class DefaultErrorChannel
                    
                    def marshal( message )
                        output_buffer.puts message.inspect
                    end
                        
                    protected 
                    def output_buffer
                        ( $stderr ||= STDERR )
                    end
                        
                end
            end
        end
    end
end
