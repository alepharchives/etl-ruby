# #!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Extraction
            class SqlDriver

                def initialize db_uri
                    @uri = db_uri
                    @sql_extractor = SqlExtractor.new @uri
                end

                def extract(options)
                    @sql_extractor.extract options
                    @sql_extractor.dataset
                end

                def transform(transformer, table_name, dataset, db, options = nil)
                    mapping = nil
                    if options.nil?
                        mapping = load_column_name_meta_data_for_table(table_name, db)
                    else
                        mapping = options.merge({:meta_data => load_column_name_meta_data_for_table(table_name, db)})
                    end
                    transformer.transform( dataset, :mapping => mapping)
                end
                
                def transform_dataset(transformer, dataset, options = nil)
                    mapping = nil
                    if options.nil?
                        mapping = load_column_name_meta_data_for_dataset(dataset)
                    else
                        mapping = options.merge({:meta_data => load_column_name_meta_data_for_dataset(dataset)})
                    end
                    transformer.transform( dataset, :mapping => mapping)
                end

                private
                
                def load_column_name_meta_data_for_dataset( dataset )
                    column_names = []
                    dataset.columns.each do |col|
                        column_names.push col.name
                    end
                    return column_names                    
                end

                def load_column_name_meta_data_for_table( table_name , db )
                    database = Database.new db.host, db.port, db.catalog, db.user, db.password
                    database.schema = db.schema if db.respond_to? :schema
                    column_names = database.get_column_metadata( table_name )
                    column_names.push 'environment'
                    return column_names
                end
            end
        end
    end
end
