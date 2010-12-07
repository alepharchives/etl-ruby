# #!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Processors
                # A specialized processor that sends the contents of a file to a database endpoint
                class SqlBulkLoaderProcessor < Processor
                    
                    def initialize( )
                        super( :fault_code => FaultCodes::SqlError, :response => '${response}' )
                        @err_msg  = { 
                            :db_uri => 'Database connection properties have not been specified in message header.',
                            :db_props => 'Database connection properties have not been specified in message header.'
                        }
                    end
                    
                    protected           

                    def extract_params( exchange )
                        config = exchange.context.config
                        ctx = binding()
                        [:connection_properties, :connection_string].each do | property |
                           on_invalid_payload(exchange, @err_msg[property]) if ctx.evaluate("#{property} = config.send( :#{property} )").nil?
                        end
                        
                        delimiter = inheader( :delimiter )                        
                        table_name = inheader( :table_name, true)
                        file_uri = inheader( :path, true)
                        
                        return file_uri, table_name, delimiter, ctx.connection_properties, ctx.connection_string                                                                    
                    end
                    
                    def load_column_meta_data( props, table_name )
                        database = Database.connect( props )
                        database.schema = 'public'
                        database.get_column_metadata( table_name )
                    end

                    def do_process( exchange )
                        
                        file_uri, table_name, delimiter, db_props, db_uri = extract_params(exchange)
                        columns = load_column_meta_data( db_props, table_name )

                        loader = SqlBulkLoader.new( db_uri )
                        loader.load(:file_uri => file_uri,
                            :delimiter => delimiter,
                            :mapping_rules => {
                                :table => table_name,
                                :columns => columns
                            })              
                        
                        @response = "#{file_uri} contents successfully loaded into #{table_name}."                         
                        
                    end
                    
                    def set_fault( exchange, error_description )
                        fault_message = Message.new
                        fault_message.set_header(:fault_code, FaultCodes::SqlError)
                        fault_message.set_header(:fault_description, error_description)
                        exchange.fault = fault_message
                    end
                end
            end
        end
    end
end