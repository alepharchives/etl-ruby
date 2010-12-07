# #!/usr/bin/env ruby
 
require 'rubygems'

module ETL
    module Transformation
        class StateTokenTransformerFactory
            
            include Validation
            
            @@transformers = {}
            
            def self.get_transformer( transformer_file_uri, environment )
                xformer = @@transformers[ transformer_file_uri ]
                if (xformer.nil?)
                    xformer = StateTokenTransformer.new
                    xformer.environment = environment
                    xformer.load_mapping_rules( transformer_file_uri )
                    @@transformers[ transformer_file_uri ] = xformer
                end
                return xformer
            end
        end
    end
end
