#!/usr/bin/env ruby
 
require 'rubygems'

module ETL
    module Integration
        module Engine
            
            # I represent a message passed through the pipes & filters infrastructure.
            # A message can represent an action, event or state within the system, can
            # be serialized, etc.
            class Message
                
                def initialize
                    @headers = {}
                end
                
                # Gets or sets the body of the message
                attr_accessor :body
                
                def headers
                    @headers.dup.freeze
                end
                
                def set_header( name, value )
                    @headers[ name ] = value
                end
                
                def include_header?( name )
                    @headers.has_key?( name )
                end
                
                def eql?( other )
                    return @headers.semantic_eql?( other.headers ) && @body.eql?( other.body )
                end
                
            end
        end
    end
end
