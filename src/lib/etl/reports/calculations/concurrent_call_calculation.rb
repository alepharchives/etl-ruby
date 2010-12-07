#!/usr/bin/env ruby 

require 'rubygems'
require 'etl'

module ETL
    module Reports
        module Calculations
            class ConcurrentCallCalculation
                
                include Validation
                    
                def initialize(database)
                    validate_arguments(binding())
                    @database = database
                    @sql_command_processor = SqlCommandProcessor.new(@database)
                end
                
                def calculate
                    d = Date.today - 1
                    year = d.year
                    month = d.month
                    day = d.day
                    extraction_sql = "select * from session_cost_fact inner join \"DateDimension\" as d on (date_surrogate_key = d.id) where year=#{year} and month=#{month} and day=#{day} and duration > 0"
                    exchange = extract(extraction_sql)
                    process(exchange.outbound)
                rescue Exception => ex
                    puts "Exception when calculating concurrent calls: #{ex.to_s}"
                    raise ex
                ensure
                    @database.disconnect
                end
                        
                private 
            
                def extract(query)
                    exchange = create_exchange(query)
                    @sql_command_processor.process(exchange)
                    exchange
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
            
                def process(message)
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
end