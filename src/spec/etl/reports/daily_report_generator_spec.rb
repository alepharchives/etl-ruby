#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'

include BehaviourSupport

include MIS::Framework
include ETL::Reports

include Spreadsheet

module ResultSetGeneratorTestBehaviourSupport
    
    begin
        include ResultSetTestBehaviourSupport
    rescue LoadError, NameError
        require File.expand_path(File.dirname(__FILE__)) + '/../integration/sql/spec_helper'
        retry
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

describe DailyReportGenerator do
    
    include ResultSetGeneratorTestBehaviourSupport

    it_should_behave_like "All tested constructor behaviour"
    
    before :each do
        @clazz = DailyReportGenerator
        @constructor_args = [ 'config' ]
        @config_hash = {
            :workbook => 'newworkbook',
            :source => {
                :session => 'session_query_file.yaml',
                :messaging => 'messaging_query_file.yaml',
                :chit => 'chit_query_file.yaml',
                :sdk => 'sdk_query_file.yaml',
                :usage => 'usage_query_file.yaml'
            },
            :email_body_queries_file => 'email_body_queries.yml',
            :body_file => 'email_body.txt',
            :database => {
                :user => 'mis',
                :password => 'password',
                :catalog => 'CAT_WAREHOUSE',
                :schema => 'public',
                :host => 'localhost',
                :port => '3001'
            }
        }
        
        make_hash_callable(@config_hash)
        
        DeploymentConfiguration.stub!(:new).and_return(@config_hash)
        @config = DeploymentConfiguration.new
        mock_database = dummy
        Database.stub!( :new ).and_return(mock_database)
    end
    
        it 'should create a new worksheet for each report group in the configuration files' do
            [:messaging, :session, :chit, :sdk, :usage].each do |cat|
                YAML.should_receive(:load_file).with("#{cat.to_s}_query_file.yaml").and_return(dummy)
            end
            report_generator = @clazz.new(@config)
            report_generator.generate_workbook
        end
    
        [:workbook, :source, :database].each do |key|
            it "should raise an ArgumentError if #{key} not passed" do
                lambda {
                    @config_hash[key] = nil            
                    @clazz.new @config
                }.should raise_error(ArgumentError, "#{key} not provided")
            end
        end
        
        it 'should use SqlCommandProcessor when initialized' do
            mock_database = dummy
            Database.should_receive( :new ).with(
                @config_hash.database.host, 
                @config_hash.database.port, 
                @config_hash.database.catalog, 
                @config_hash.database.user, 
                @config_hash.database.password,
                :disconnected => true).and_return(mock_database)
            SqlCommandProcessor.should_receive( :new ).with(mock_database)
            @clazz.new @config
        end
        
        it 'should create a new worksheet using the Spreadsheet::Excel class' do
            original_name = "xxxworkbook"
            [:messaging, :session, :chit, :sdk, :usage].each do |cat|
                workbook_name = "xxxworkbook.#{cat}.#{Time.now.strftime('%d-%m-%Y')}.xls"
                @config_hash[:workbook] = original_name
                YAML.stub!(:load_file).and_return(dummy)
                Spreadsheet::Excel.should_receive(:new).with(workbook_name).and_return(duck)
            end
            
            ObjectToExcelTransformer.stub!(:new)
            generator = @clazz.new(@config)
            generator.execute
        end
    
    it 'should use ObjectToExcelTransformer to transform excel file' do
        mock_workbook = dummy
         
        YAML.stub!(:load_file).and_return(dummy)
        Spreadsheet::Excel.stub!(:new).and_return(mock_workbook)
        ObjectToExcelTransformer.should_receive(:new).with(mock_workbook).exactly(5)
        
        generator = @clazz.new(@config)
        generator.execute
    end
    
        it 'should pass the sql query to the command processor' do
            report1 = {:title => 'title', :description => 'description', :sql => 'sql_a'}
            report2 = {:title => 'title2', :description => 'description2', :sql => 'sql_b'}
            queries = {:report1 => report1, :report2 => report2} 
            mock_commandprocessor = dummy
            SqlCommandProcessor.stub!(:new).and_return(mock_commandprocessor)
            generator = @clazz.new @config
            
            YAML.stub!(:load_file).and_return(queries)
            mock_commandprocessor.should_receive(:process).exactly(@config.source.length * queries.length);
            
            generator.generate_workbook
        end
           
        it 'should add a new worksheet for each report with correct worksheet name' do
            report1 = {:title => 'title', :description => 'description', :sql => 'sql_a'}
            queries = {:report1 => report1}
            mock_commandprocessor = dummy
            mock_transformer = dummy
            dataset = instantitate_resultset(get_dummy_result)
            
            SqlCommandProcessor.stub!(:new).and_return(mock_commandprocessor)
            ObjectToExcelTransformer.stub!(:new).and_return(mock_transformer)
            
            generator = @clazz.new @config
            
            YAML.stub!(:load_file).and_return(queries)
            
            command = Message.new          
            command.set_header(:command, :SQL)
            command.set_header(:command_type, :DDL)
            command.set_header(:response, dataset)
            command.body = nil
            exchange = Exchange.new(ExecutionContext.new())
            exchange.outbound = command
    
            generator.stub!(:extract).and_return(exchange)
            mock_transformer.should_receive(:transform).with(dataset, :mapping => {:worksheet => 'report1', :meta_data => ['col1', 'col2'], :query => report1}).exactly(@config.source.length)
            
            generator.generate_workbook
        end
        
        it "should calculate concurrent calls" do
            generator = @clazz.new @config
            
            generator.should_receive(:process_concurrent_calls)
            
            generator.calculate_concurrent_calls
        end
    
        it "should call commands in a correct order" do
            #setup
            generator = @clazz.new @config
            
            #expectations
            generator.should_receive(:calculate_concurrent_calls).ordered
            generator.should_receive(:generate_workbook).ordered
            generator.should_receive(:generate_email_body).ordered
            
            #act
            generator.execute
        end

end
