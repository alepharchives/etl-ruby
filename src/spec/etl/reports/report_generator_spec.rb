#!/usr/bin/env ruby

require 'rubygems'
#require 'actionmailer'

require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'


include BehaviourSupport

include MIS::Engine
include MIS::Framework
include ETL::Reports

include Spreadsheet

# Although this class is not used but this is how we should write a Mailer using actionmailer
module Email
    class Mailer
        def self.send_message(to, sender, subject, file_names, body_text)
            puts "To:#{to}, Sender:#{sender}"
        end
    end
end

module ResultSetGeneratorTestBehaviourSupport
    
    begin
        include ResultSetTestBehaviourSupport
    rescue LoadError, NameError
        require File.expand_path(File.dirname(__FILE__)) + '/../integration/sql/spec_helper'
        retry
    end
    
    def get_count_dataset
        count = count Varchar
        avg = col2 Varchar
        PostgresPR::Connection::Result.new( get_dummy_counts, [count, avg])
        #PostgresPR::Connection::Result.new( [count, avg], get_dummy_counts)
    end

    def get_dummy_counts
        (1..1).collect { |index| [ '12', '15' ] }
    end
    
    def get_dummy_result
        col1 = col1 Varchar
        col2 = col2 Varchar
        PostgresPR::Connection::Result.new( get_dummy_rows, [ col1, col2 ] )
    end
    
    def get_dummy_rows
        (1..3).collect { |index| [ "col1_#{index}", "col2_#{index}" ] }
    end
end

describe ETL::Reports::ReportGenerator do
    
    include ResultSetGeneratorTestBehaviourSupport

    it_should_behave_like "All tested constructor behaviour"
    
    before :each do
        @clazz = ReportGenerator
        @constructor_args = [ 'config', 'report_set_filename', 'mailer' ]
        @config_hash = {
            :path_to_report_config => '../test',
            :database => {
                :user => 'mis',
                :password => 'password',
                :catalog => 'CAT_WAREHOUSE',
                :host => 'localhost',
                :port => '3001'
            }
        }
        @report_definition_hash = {
            :reports => {
                :chit => 
                    [:chit_usage_report,
                    :top_chit_using_apps,
                    :chit_purchase,
                    :chits_remaining_report,
                    :chit_credit_debit],
                :messaging =>
                    [:sms_by_country,
                    :sms_usage_by_environment,
                    :sms_usage_by_application,
                    :sms_usage_trend,
                    :sms_revenue_report]
            },
            :recipients =>
                'nauman.laghari@sb-domain.com, gabriela.marcionetti@sb-domain.com',
            :sender =>
                'nauman.laghari@sb-domain.com',
            :email_subject =>
                'Daily Report',
            :email_header =>
                'Daily counts from yesterday:',
            :email_body_queries =>
                'third_party_session_count,
                capability_usage_count,
                concurrent_calls_max,
                sdk_downloads_count,
                session_cost_count'
        }
        
        make_hash_callable(@config_hash)
        make_hash_callable(@report_definition_hash)
        
        DeploymentConfiguration.stub!(:new).and_return(@config_hash)
        @config = DeploymentConfiguration.new
        mock_database = dummy
        Database.stub!( :new ).and_return(mock_database)
    end
    
    [:path_to_report_config, :database].each do |key|
        it "should raise an ArgumentError if #{key} not passed" do
            lambda {
                @config_hash[key] = nil            
                @clazz.new @config, 'report_set_file', duck
            }.should raise_error(ArgumentError, "#{key} not provided")
        end
    end
    
    it 'should use SqlCommandProcessor when initialized' do
        File.stub!(:file?).and_return(true)
        
        file_path = File.expand_path( @config.path_to_report_config + '/report_set_file.yml')    
        
        YAML.should_receive(:load_file).with(file_path).and_return(@report_definition_hash)
        mock_database = dummy
        Database.should_receive( :new ).with(
            @config_hash.database.host, 
            @config_hash.database.port, 
            @config_hash.database.catalog, 
            @config_hash.database.user, 
            @config_hash.database.password,
            :disconnected => true).and_return(mock_database)
        SqlCommandProcessor.should_receive( :new ).with(mock_database)
        @clazz.new @config, 'report_set_file.yml', duck
    end
        
    it 'should load the report set file and return a valid data for the report set' do
        File.stub!(:file?).and_return(true)
        
        file_path = File.expand_path( @config.path_to_report_config + '/test_report_set.yml')    
        
        YAML.should_receive(:load_file).with(file_path).and_return(@report_definition_hash)
        @clazz.new(@config, 'test_report_set.yml', duck)
    end
    
    [:reports].each do |key|
        it "should raise an ArgumentError if #{key} not passed" do
            lambda {
                File.stub!(:file?).and_return(true)
                YAML.stub!(:load_file).and_return(@report_definition_hash)
                @report_definition_hash[key] = nil            
                @clazz.new @config, 'report_set_file.yml', duck
            }.should raise_error(ArgumentError, "#{key} not provided")
        end
    end
end

describe ReportGenerator do
    
    include ResultSetGeneratorTestBehaviourSupport

    it_should_behave_like "All tested constructor behaviour"
    
    before :each do
        @clazz = ReportGenerator
        @constructor_args = [ 'config', 'report_set_filename', 'mailer' ]
        @config_hash = {
            :path_to_report_config => 'c:/test',
            :database => {
                :user => 'mis',
                :password => 'password',
                :catalog => 'CAT_WAREHOUSE',
                :host => 'localhost',
                :port => '3001'
            }
        }
        @report_definition_hash = {
            :reports => {
                :chit => 
                    [:chit_usage_report,
                    :top_chit_using_apps,
                    :chit_purchase,
                    :chits_remaining_report,
                    :chit_credit_debit],
                :messaging =>
                    [:sms_by_country,
                    :sms_usage_by_environment,
                    :sms_usage_by_application,
                    :sms_usage_trend,
                    :sms_revenue_report]
            },
            :recipients =>
                'nauman.laghari@sb-domain.com, gabriela.marcionetti@sb-domain.com',
            :sender =>
                'nauman.laghari@sb-domain.com',
            :email_subject =>
                'Daily Report',
            :email_header =>
                'Daily counts from yesterday:',
            :email_body_queries =>
                'third_party_session_count,
                capability_usage_count,
                concurrent_calls_max,
                sdk_downloads_count,
                session_cost_count'
        }
        @query_hash = {
            :title => 'title', :description => 'description', :sql => 'sql_a'
        }
        
        make_hash_callable(@config_hash)
        make_hash_callable(@report_definition_hash)
        make_hash_callable(@query_hash)
        
        DeploymentConfiguration.stub!(:new).and_return(@config_hash)
        @config = DeploymentConfiguration.new
        mock_database = dummy 
        Database.stub!( :new ).and_return(mock_database)
        File.stub!(:file?).and_return(true)
        YAML.stub!(:load_file).and_return(@report_definition_hash)
        @mock_transformer = dummy
        @mock_commandprocessor = dummy
        SqlCommandProcessor.stub!(:new).and_return(@mock_commandprocessor)
        ObjectToExcelTransformer.stub!(:new).and_return(@mock_transformer)
        @report_generator = @clazz.new @config, 'report_set_file.yml', duck
    end
    
    it 'should load the query file for each query in the report group' do
        [:chit_usage_report, :top_chit_using_apps, :chit_purchase, :chits_remaining_report, :chit_credit_debit, :sms_by_country,
            :sms_usage_by_environment,
            :sms_usage_by_application,
            :sms_usage_trend,
            :sms_revenue_report].each do |query|
            
        File.stub!(:file?).and_return(true)
        file_path = File.expand_path( @config.path_to_report_config + "/../queries/#{query.to_s}.yml")    
        q_hash = {
            query.to_s => @query_hash
        }
        YAML.should_receive(:load_file).with(file_path).and_return(q_hash)
        end
        @report_generator.generate_workbook
    end
    
    it 'should use ObjectToExcelTransformer to transform excel files' do
       
        mock_workbook = dummy
        
        Spreadsheet::Excel.stub!(:new).and_return(mock_workbook)
        ObjectToExcelTransformer.should_receive(:new).with(mock_workbook).exactly(2)
        
        @report_generator.stub!(:load_query).and_return(@query_hash)
        @report_generator.generate_workbook
    end
    
    it 'should pass the query to the SQLCommandProcessor' do
        @report_generator.stub!(:load_query).and_return(@query_hash)
        @mock_commandprocessor.should_receive(:process).exactly(10);
        @report_generator.generate_workbook
    end

    it 'should create a excel spreadsheet for each report group in the report_set files and return the array of file names' do
        workbook_names = []
        [:chit, :messaging].each do |cat|
            workbook_name = "report_set_file.#{cat}.#{Time.now.strftime('%d-%m-%Y')}.xls"
            workbook_names << workbook_name
            Spreadsheet::Excel.should_receive(:new).with(workbook_name).and_return(duck)
        end
        @report_generator.stub!(:load_query).and_return(@query_hash)
        names = @report_generator.generate_workbook 
        workbook_names.each do |filename|
            names.should include(filename)
        end      
    end
        
    it 'should add a new worksheet for each report with correct worksheet name' do
        dataset = instantitate_resultset(get_dummy_result)
        command = Message.new          
        command.set_header(:command, :SQL)
        command.set_header(:command_type, :DDL)
        command.set_header(:response, dataset)
        command.body = nil
        exchange = Exchange.new(ExecutionContext.new())
        exchange.outbound = command

        [:chit_usage_report].each do |query|
            @report_generator.stub!(:load_query).and_return(@query_hash)
            @report_generator.stub!(:extract).and_return(exchange)
            @mock_transformer.should_receive(:transform).with(dataset, :mapping => 
                    {:worksheet => query.to_s, :meta_data => ['col1', 'col2'], :query => @query_hash})
        end
        
        
        @report_generator.generate_workbook
    end
end

describe ReportGenerator do
    
    include ResultSetGeneratorTestBehaviourSupport

    it_should_behave_like "All tested constructor behaviour"
    
    before :each do
        @clazz = ReportGenerator
        @constructor_args = [ 'config', 'report_set_filename' , 'mailer' ]
        @config_hash = {
            :path_to_report_config => 'c:/test',
            :smtp_server => 'smtp_server',
            :database => {
                :user => 'mis',
                :password => 'password',
                :catalog => 'CAT_WAREHOUSE',
                :host => 'localhost',
                :port => '3001'
            }
        }
        @report_definition_hash = {
            :reports => {},
            :recipients =>
                'nauman.laghari@sb-domain.com, gabriela.marcionetti@sb-domain.com',
            :sender =>
                'nauman.laghari@sb-domain.com',
            :email_subject =>
                'Daily Report',
            :email_header =>
                'Daily counts from yesterday:',
            :email_body_queries =>
                [:third_party_session_count,
                :capability_usage_count]
        }
        
        make_hash_callable(@config_hash)
        make_hash_callable(@report_definition_hash)
        
        
        DeploymentConfiguration.stub!(:new).and_return(@config_hash)
        @config = DeploymentConfiguration.new
        mock_database = dummy
        Database.stub!( :new ).and_return(mock_database)

        File.stub!(:file?).and_return(true)
        YAML.stub!(:load_file).and_return(@report_definition_hash)
        @mock_transformer = dummy
        @mock_commandprocessor = dummy
        SqlCommandProcessor.stub!(:new).and_return(@mock_commandprocessor)
        ObjectToExcelTransformer.stub!(:new).and_return(@mock_transformer)
        @report_generator = @clazz.new @config, 'report_set_file.yml', duck
        
        @report_generator.stub!(:generate_workbook).and_return(['abc', 'xyz'])
    end    
    
    [:recipients, :sender, :email_subject].each do |key|
        it 'should validate that the #{key} contains valid data before creating email' do
            lambda {
                @report_definition_hash[key] = nil            
                @report_generator.generate_and_email_workbook
            }.should raise_error(ArgumentError, "#{key} not provided")
            
        end
    end
    
    [:email_header, :email_body_queries].each do |key|
        it 'should not raise error if #{key} is not defined in the config' do
            lambda {
                @report_generator.stub!(:get_dataset)
                EmailEndpoint.stub!(:deliver_report)
                @report_generator.stub!(:get_result_for_query).and_return("")
                @report_definition_hash[key] = nil
                @report_generator.generate_and_email_workbook
            }.should_not raise_error()
        end    
    end     
    
        it 'should load each "email_body_queries" query from the yaml file' do
            EmailEndpoint.stub!(:deliver_report)
            @report_generator.stub!(:get_result_for_query).and_return("count: 3")
            @report_definition_hash.email_body_queries.each do |query_file|
            file_path = File.expand_path( @config.path_to_report_config + "/../queries/#{query_file}.yml" )    
            YAML.should_receive(:load_file).with( file_path).and_return(duck)
            end
            @report_generator.generate_and_email_workbook
        end
        
        it 'should call the EmailEndpoint with the correct parameters' do
            mock_emailendpoint = dummy
            @report_generator.stub!(:get_report_delivery).and_return(mock_emailendpoint)
            @report_generator.stub!(:get_email_body_for_queries).and_return("count: 3")
            mock_emailendpoint.should_receive(:deliver_report) do |to, sender, subject, filenames, body_text|
                to.should eql(@report_definition_hash.recipients)
                sender.should eql(@report_definition_hash.sender)
                subject.should eql(@report_definition_hash.email_subject)
                filenames.should eql(['abc', 'xyz'])
                body_text.should match(/^#{@report_definition_hash.email_header}/)
            end
            @report_generator.generate_and_email_workbook
        end    
end

describe ReportGenerator do
    
    include ResultSetGeneratorTestBehaviourSupport

    it_should_behave_like "All tested constructor behaviour"
    
    before :each do
        @clazz = ReportGenerator
        @constructor_args = [ 'config', 'report_set_filename', 'mailer' ]
        @config_hash = {
            :path_to_report_config => 'c:/test',
            :database => {
                :user => 'mis',
                :password => 'password',
                :catalog => 'CAT_WAREHOUSE',
                :host => 'localhost',
                :port => '3001'
            }
        }
        @report_definition_hash = {
            :reports => {},
            :recipients =>
                'nauman.laghari@sb-domain.com, gabriela.marcionetti@sb-domain.com',
            :sender =>
                'nauman.laghari@sb-domain.com',
            :email_subject =>
                'Daily Report',
            :email_header =>
                'Daily counts from yesterday:',
            :email_body_queries =>
                [:third_party_session_count],
            :calculation_queries =>
                ['ConcurrentCallCalculation']
        }
        
        make_hash_callable(@config_hash)
        make_hash_callable(@report_definition_hash)
        
        DeploymentConfiguration.stub!(:new).and_return(@config_hash)
        @config = DeploymentConfiguration.new
        mock_database = dummy
        Database.stub!( :new ).and_return(mock_database)

        File.stub!(:file?).and_return(true)
        YAML.stub!(:load_file).and_return(@report_definition_hash)
        @mock_transformer = dummy
        @mock_commandprocessor = dummy
        SqlCommandProcessor.stub!(:new).and_return(@mock_commandprocessor)
        ObjectToExcelTransformer.stub!(:new).and_return(@mock_transformer)
        @report_generator = @clazz.new @config, 'report_set_file.yml', duck
        
        @report_generator.stub!(:create_excel_files).and_return(['abc', 'xyz'])
    end
    
    it 'should correctly populate the email body with the query description and value' do
        query_hash_a = {
            :title => 'title', :description => 'A description', :sql => 'email_sql_a'
        }
        make_hash_callable(query_hash_a)
        mock_emailendpoint = dummy
        dataset = instantitate_resultset(get_count_dataset)
        @report_generator.stub!(:get_report_delivery).and_return(mock_emailendpoint)
        @report_generator.stub!(:load_query).and_return(query_hash_a)
        @report_generator.stub!(:get_dataset).and_return(dataset)
        mock_emailendpoint.should_receive(:deliver_report) do |to, sender, subject, filenames, body_text|
            body_text.should match(/^#{@report_definition_hash.email_header}/)
            body_text.should include('A description: 12')
        end
        @report_generator.generate_and_email_workbook
    end 
end

describe ReportGenerator do
    
    include ResultSetGeneratorTestBehaviourSupport

    it_should_behave_like "All tested constructor behaviour"
    
    before :each do
        @clazz = ReportGenerator
        @constructor_args = [ 'config', 'report_set_filename', 'mailer' ]
        @config_hash = {
            :path_to_report_config => 'c:/test',
            :database => {
                :user => 'mis',
                :password => 'password',
                :catalog => 'CAT_WAREHOUSE',
                :host => 'localhost',
                :port => '3001'
            }
        }
        @report_definition_hash = {
            :reports => {
                :messaging =>
                    [:sms_by_country]
            },
            :parameters => [2,5,2008]
        }
        @query_hash = {
            :title => 'title', :description => 'description', :sql => 'sql_a'
        }
        
        make_hash_callable(@config_hash)
        make_hash_callable(@report_definition_hash)
        make_hash_callable(@query_hash)
        
        DeploymentConfiguration.stub!(:new).and_return(@config_hash)
        @config = DeploymentConfiguration.new
        mock_database = dummy 
        Database.stub!( :new ).and_return(mock_database)
        File.stub!(:file?).and_return(true)
        YAML.stub!(:load_file).and_return(@report_definition_hash)
        @mock_transformer = dummy
        @mock_commandprocessor = dummy
        SqlCommandProcessor.stub!(:new).and_return(@mock_commandprocessor)
        ObjectToExcelTransformer.stub!(:new).and_return(@mock_transformer)
        @report_generator = @clazz.new @config, 'report_set_file.yml', duck
    end
    
    it 'should pass the query to the SQLCommandProcessor' do
        @report_generator.stub!(:load_query).and_return(@query_hash)
        @mock_commandprocessor.should_receive(:process).exactly(1).and_return(duck) do |exchange|
            exchange.inbound.headers[:params].should eql(@report_definition_hash.parameters)
        end
            
        @report_generator.generate_workbook
    end
    
    def get_dummy_exchange_with_params(params)
        command = Message.new          
        command.set_header(:command, :SQL)
        command.set_header(:command_type, :DDL)
        command.set_header(:params, params)
        command.body = duck
        exchange = Exchange.new(dummy)
        exchange.inbound = command
        exchange
    end
end