#!/usr/bin/env ruby

require 'rubygems'
require 'spec'
require 'spreadsheet/excel'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'
include BehaviourSupport

include MIS::Framework
include Spreadsheet

module ResultSetTransformTestBehaviourSupport
    
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


describe given( ETL::Transformation::ObjectToExcelTransformer ) do
    
    include ResultSetTransformTestBehaviourSupport
    
    it_should_behave_like "All tested constructor behaviour"

    before :each do
        @clazz = ObjectToExcelTransformer
        @constructor_args = [ 'workbook' ]
    end
    
    it 'should validate the options before writing to spreadsheet' do
        options = {}
        transformer = @clazz.new ''
        [:worksheet, :meta_data].each do |opts|
            lambda{ 
                options = {:worksheet=>"worksheet.xls"} if opts == :meta_data
                options = {:meta_data=>["col1", "col2", "environment"]} if opts == :worksheet
                transformer.transform(dummy, :mapping => options)
            }.should raise_error(ArgumentError, "#{opts.to_s} not present in options")
        end
    end
    
    it 'should add a new worksheet in transform' do
        mock_workbook = dummy
        mock_worksheet = duck
        worksheet_name = "newworksheet"
        mock_workbook.should_receive(:add_worksheet).with(worksheet_name).and_return(mock_worksheet)
        options = {:worksheet => worksheet_name, :meta_data => [], :query => dummy}
        transformer = @clazz.new mock_workbook
        transformer.transform(dummy, :mapping => options)
    end

    it 'should all title and description in the worksheet' do
        mock_workbook = dummy
        worksheet_name = dummy
        mock_worksheet = dummy
        meta_data = ['col1', 'col2']
        title = 'dummy title'
        description = 'dummy description'
        sql = 'select everything'
        query = get_dummy_query(title, description, sql)

        mock_workbook.stub!(:add_worksheet).and_return(mock_worksheet)
        
        mock_worksheet.should_receive(:write).with(0, 0,"Title: #{title.camelize}")
        mock_worksheet.should_receive(:write).with(1, 0, "Description: #{description.camelize}")
        mock_worksheet.should_receive(:write).with(2, 0, "Query: #{sql}")
        
        meta_data.each_with_index do |header, i|
            mock_worksheet.should_receive(:write).with(4, i, header.camelize, anything)
        end
        
        options = {:worksheet => worksheet_name, :meta_data => meta_data, :query => query}
        transformer = @clazz.new mock_workbook
        transformer.transform(dummy, :mapping => options)
    end
    
    it 'should add data under the appropriate headers' do
        mock_workbook = dummy
        worksheet_name = dummy
        mock_worksheet = dummy
        dataset = instantitate_resultset(get_dummy_result)
            
        transformer = @clazz.new mock_workbook
            
        meta_data = ['col1', 'col2']
        query = {}
        Spreadsheet::Excel.stub!(:new).and_return(mock_workbook)
        transformer.stub!(:add_worksheet).and_return(mock_worksheet)
        options = {:worksheet => worksheet_name, :meta_data => meta_data, :query => query}
        transformer.should_receive(:add_headers).with(meta_data, query, mock_worksheet)
           
        dataset.rows.each_with_index do |row, rindex|
            meta_data.each_with_index do |col, cindex|
                mock_worksheet.should_receive(:write).with(rindex + 6, cindex, row[col].to_s, anything)
            end
        end
            
        transformer.transform(dataset, :mapping => options)
    end    
end

def get_dummy_query(title, description, sql)
    query = {:title => title, :description => description, :sql => sql}
    return query
end