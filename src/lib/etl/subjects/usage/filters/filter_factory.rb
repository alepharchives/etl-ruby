#!/usr/bin/env ruby
 
require 'rubygems'
require 'date'

module ETL
    module Subjects
        module Usage
            module Filters
                class FilterFactory
                    
                    mixin Validation
                    
                    def initialize (environment_name)
                        valid_environment(environment_name)
                        @environment_name = environment_name
                    end
                    
                    def get_parsing_filter(logfile_date=nil)
                        return ( @parsing_filter_instance ||= create_parsing_filter )
                    end
                end
            end
        end
    end
end
