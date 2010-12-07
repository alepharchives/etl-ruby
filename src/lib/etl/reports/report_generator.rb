#!/usr/bin/env ruby 

require 'rubygems'
require 'etl'

module ETL
    module Reports
        class ReportGenerator
            
            include Validation
                    
            def initialize(config, report_set_filename, mailer)
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
                @report_set_filename = report_set_filename
                @report_set_config = load_report_set()
                @mailer = mailer
            end
            
            def generate_workbook
                create_calculations
                create_excel_files
            end
            
            def generate_and_email_workbook
                validate_email_properties
                filenames = generate_workbook
                send_email(filenames)
            end

            private
            
            
            def create_calculations
                return unless @report_set_config.respond_to? :calculation_queries
                ## call the calculation classes
                @report_set_config.calculation_queries.each do |calculation_class|
                    calculator = nil
                    begin
                        calculator = eval("Calculations::#{calculation_class}").new(@database)
                        calculator.calculate
                    rescue Exception => ex
                        puts "Exception processing calculation class: #{calculation_class}, #{ex}."
                    end          
                end
            end
            
            def create_excel_files
                @report_names = []
                @report_set_config.reports.each do |report_group|
                    report_set_name = File.basename(@report_set_filename, '.yml')
                    filename = "#{report_set_name}.#{report_group[0]}.#{Time.now.strftime('%d-%m-%Y')}.xls"
                    @report_names << filename
                    workbook = Spreadsheet::Excel.new(filename)
                    transformer = ObjectToExcelTransformer.new(workbook)
                    report_group[1].each do |queryfile|
                        puts "Processing #{queryfile}" 
                        query = load_query(queryfile)
                        response = extract(query.sql)
                        transform(queryfile, response.outbound, query, transformer)
                    end
                    workbook.close
                end
                @report_names
            end
            
            def load_query(queryfile)
                file_path = File.expand_path( @config.path_to_report_config + "/../queries/#{queryfile}.yml" )
                query_file = YAML::load_file(file_path)
                query_hash = query_file[queryfile.to_s]
                make_hash_callable(query_hash) unless query_hash.nil?
                query_hash
            end
            
            def validate_configuration(config)
                [:path_to_report_config, :database].each do |config_item|
                    raise ArgumentError, "#{config_item} not provided", caller if eval("config.#{config_item}.nil?")
                end
            end
            
            def load_report_set()
                path = File.expand_path( @config.path_to_report_config + '/' + @report_set_filename)    
                @report_set_config = YAML::load_file(path) if File.file? path
                make_hash_callable(@report_set_config)
                validate_report_set_config(@report_set_config) unless @report_set_config.nil?
            end
            
            def validate_report_set_config(report_set_config)
                [:reports].each do |config_item|
                    raise ArgumentError, "#{config_item} not provided", caller if eval("report_set_config.#{config_item}.nil?")
                end
                report_set_config
            end
            
            def extract(query)
                exchange = create_exchange(query)
                @sql_command_processor.process(exchange)
                exchange
            end
            
            def create_exchange(sql)
                command = Message.new          
                command.set_header(:command, :SQL)
                command.set_header(:command_type, :DDL)
                command.set_header(:params, get_parameters)
                command.body = sql
                exchange = Exchange.new(ExecutionContext.new())
                exchange.inbound = command
                exchange
            end
            
            def get_parameters
                @report_set_config.parameters if @report_set_config.respond_to? :parameters
            end
            
            def transform(sheet_name, message, query, transformer)
                return if message.nil?
                dataset = message.headers[:response]
                columns = load_columns_meta_data(dataset)
                transformer.transform(dataset, :mapping => 
                        {:worksheet => sheet_name.to_s, :meta_data => columns, :query => query})
            end
            
            def load_columns_meta_data(dataset)
                column_names = []
                dataset.columns.each do |col|
                    column_names.push col.name
                end
                return column_names                    
            end
            
            def validate_email_properties
                [:recipients, :sender, :email_subject].each do |config_item|
                    raise ArgumentError, "#{config_item} not provided", caller if eval("@report_set_config.#{config_item}.nil?")
                end
            end
            
            def send_email(filenames)
                email_body = create_email_body
                get_report_delivery().deliver_report(@report_set_config.recipients,
                    @report_set_config.sender,
                    @report_set_config.email_subject,
                    filenames,
                    email_body)
            end
            
            def get_report_delivery
                EmailEndpoint.new(@mailer)
            end
            
            def create_email_body
                email_body = ""
                email_body << @report_set_config.email_header + '<br>' unless @report_set_config.email_header.nil?
                email_body << get_email_body_for_queries
                #email_body << get_calculations
                email_body
            end
            
            def get_email_body_for_queries
                email = ""
                unless @report_set_config.email_body_queries.nil?
                    @report_set_config.email_body_queries.each do |email_query|
                        query_file = load_query(email_query)
                        email << get_result_for_query(query_file)
                    end
                end
                email
            end
            
            def get_result_for_query query_file
                dataset = get_dataset(query_file.sql)
                "#{query_file.description}: #{dataset.rows.first.count}<br>"
            end
            
            def get_dataset(query)
                response = extract(query)
                unless response.nil?
                    response.outbound.headers[:response] 
                end
            end
        end
    end
end