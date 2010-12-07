#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Processors
                # A processor that deals with transforming parsing output into a database ready format
                class TransformerProcessor < Processor
                    
                    include Validation
                    
                    def initialize( transformer_file_uri )
                        validate_arguments(binding())
                        super( :fault_code => FaultCodes::TransformerError )
                        @transformer_file_uri = transformer_file_uri
                    end
                   
                    protected                    
                    def do_process( exchange )
                        env = inheader( :environment )
                        xformer = StateTokenTransformerFactory.get_transformer( @transformer_file_uri, env )
                        result = xformer.transform( exchange.inbound.body )
                        
                        response = Message.new
                        response.set_header(:delimiter, '|')
                        response.body = result
                        exchange.outbound = response
                    end
                end
            end
        end
    end
end
