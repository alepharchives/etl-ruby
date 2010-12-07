#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module Processors
		
                # Performs rules based multiplexed routing
                class MulticastRouter < Router  #TODO: rename to multiplex-router instead (it doesn't multicast at all does it!)
                    
                    def initialize()
                        super()
                    end
                    
                    protected
                    
                    def routes
                        if @routes.nil?
                            @routes = [] 
                            def @routes.redirect?( data_exchange )
                                return self.collect { |route| 
                                    route.redirect?( data_exchange ) 
                                }.include?( true )
                            end
                        end
                        @routes
                    end
                                        
                end
            end
        end
    end
end
