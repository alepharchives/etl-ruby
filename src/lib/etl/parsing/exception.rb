#!/usr/bin/env ruby

require 'rubygems'

include ETL

module ETL
    module Parsing

        class ParseError < BaseException
	    attr_reader :error_data, :message
            def initialize(error_data=nil, message=nil) 
		@error_data, @message = error_data, message
            end
            
            def body()
                error_message = self.error_data.states.last.message
                info = "Original Line: #{self.error_data.raw_input}"
                return "#{error_message}, #{info}"
            end
            
        end

    end
end
