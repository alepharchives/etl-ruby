#!/usr/bin/env ruby 

require 'rubygems'
require 'etl'

module ETL
    module Reports
        class DailyReportGenerator
            
            include Validation
                    
            def initialize(config)
                validate_arguments(binding())
                validate_configuration(config)
                @config = config
                @database = Database.new(
                    config.database.host, 
                    config.database.port, 
                    config.database.catalog, 
                    config.database.user, 
                    config.database.password,
                    :disconnected => true)
                @sql_command_processor = SqlCommandProcessor.new(@database)
                # add current date to worksheet name
            end
            
            def execute()
                calculate_concurrent_calls
                generate_workbook
                generate_email_body
            end
            
            def generate_workbook
                @config.source.each do |type, config_file|
                    filename = "#{@config.workbook}.#{type}.#{Time.now.strftime('%d-%m-%Y')}.xls"
                    workbook = Spreadsheet::Excel.new(filename)
                    transformer = ObjectToExcelTransformer.new(workbook)
                    queries = YAML::load_file(config_file)
                    return if queries.nil?
                    queries.each do |column_name, query|
                        make_hash_callable(query)
                        response = extract(query.sql)
                        transform(column_name, response.outbound, query, transformer)
                    end
                    workbook.close       
                end
                        
            end

            def calculate_concurrent_calls
                date = Time.now.strftime("%Y/%m/%d").split('/')
                year = date[0]
                month = date[1]
                day = (date[2].to_i - 1).to_s
                extraction_sql = "select * from session_cost_fact inner join \"DateDimension\" as d on (date_surrogate_key = d.id) where year=#{year} and month=#{month} and day=#{day} and duration > 0"
                exchange = extract(extraction_sql)
                process_concurrent_calls(exchange.outbound)
            rescue Exception => ex
                puts "Exception when calculating concurrent calls: #{ex.to_s}"
            ensure
                @database.disconnect
            end

            def generate_email_body
                queries = YAML::load_file(@config.email_body_queries_file)
                return if queries.nil?

                output = "Daily counts:\n\n"
                queries.each do |column_name, query|
                    make_hash_callable(query)
                    response = extract(query.sql)
                    dataset = response.outbound.headers[:response]
                    output << "#{query.description} -  #{dataset.rows[0].count}<br>"
                end
                File.open(@config.body_file, "w") { |f|
                    f << output
                }
            end
                        
            private 
            
            def extract(query)
                exchange = create_exchange(query)
                @sql_command_processor.process(exchange)
                exchange
            end
            
            def process_concurrent_calls(message)
                return if message.nil?
                dataset = message.headers[:response]
                
                @database.connect
                @database.execute 'delete from concurrent_calls'
        
                i = 0
                dataset.rows.each do |row1|
                    i = i+1
                    start_time1 = get_start_seconds( row1 )
                    stop_time1 = get_end_seconds( row1 )
                    puts "processing row nr: #{i}"
                    j = 0
                    concurrent_calls = 0
                    concurrent_with = ""
                    dataset.rows.each do |row2|
                        j = j+1
                        start_time2 = get_start_seconds( row2 )
                        stop_time2 = get_end_seconds( row2 )
                        if ( (start_time2 >= start_time1 && start_time2<= stop_time1) ||
                                    (stop_time2 >= start_time1 && stop_time2<= stop_time1) )
                            concurrent_calls = concurrent_calls + 1
                            concurrent_with = "#{concurrent_with}, #{row2.id}"
                        end
                    end
                    session_time = row1.session_time.strftime("%H:%M:%S")
                    sql = "INSERT INTO concurrent_calls VALUES(#{row1.id}, #{row1.date_surrogate_key}, '#{session_time}', #{concurrent_calls.to_s})"
                    @database.execute sql
                end                
            end

            def transform(column_name, message, query, transformer)
                return if message.nil?
                dataset = message.headers[:response]
                columns = load_columns_meta_data(dataset)
                transformer.transform(dataset, :mapping => 
                        {:worksheet => column_name.to_s, :meta_data => columns, :query => query})
            end
            
            def validate_configuration(config)
                [:workbook, :source, :database].each do |config_item|
                    raise ArgumentError, "#{config_item} not provided", caller if eval("config.#{config_item}.nil?")
                end
            end
            
            def load_columns_meta_data(dataset)
                column_names = []
                dataset.columns.each do |col|
                    column_names.push col.name
                end
                return column_names                    
            end
      
            def create_exchange(sql)
                command = Message.new          
                command.set_header(:command, :SQL)
                command.set_header(:command_type, :DDL)
                command.body = sql
                exchange = Exchange.new(ExecutionContext.new())
                exchange.inbound = command
                exchange
            end
            
            def get_start_seconds( row )
                seconds_from_day = (row.date_surrogate_key - 3288) * 86400
                seconds_from_hour = row.session_time.hour.to_i * 3600
                seconds_from_min = row.session_time.min.to_i * 60
                seconds_from_sec = row.session_time.sec.to_i
                start_seconds = seconds_from_day + seconds_from_hour + seconds_from_min + seconds_from_sec    
            end

            def get_end_seconds( row )
                seconds_from_day = (row.date_surrogate_key - 3288) * 86400
                seconds_from_hour = row.session_time.hour.to_i * 3600
                seconds_from_min = row.session_time.min.to_i * 60
                seconds_from_sec = row.session_time.sec.to_i
                end_seconds = seconds_from_day + seconds_from_hour + seconds_from_min + seconds_from_sec + row.duration
            end

        end
    end
end
