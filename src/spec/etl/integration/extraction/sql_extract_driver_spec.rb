# #!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../../")  + '/spec_helper'

include BehaviourSupport
include MIS::Framework

# Is used to extract data from a database table into a dump file

describe given( ETL::Integration::Extraction::SqlDriver ), 'when creating a new sql extract driver' do

    it 'should initialize sql extractor with correct configuration data' do
        db_config = 'anything'
        SqlExtractor.should_receive(:new).once.with(db_config)
        @sql_extract_driver = SqlDriver.new db_config
    end
end


describe given( ETL::Integration::Extraction::SqlDriver ), 'when supplied with a correct table name for a database' do

    before :each do
        @dataset = 'dataset'
        @db = {
            :database => {
                :user => 'user',
                :password => 'password',
                :catalog => 'catalog',
                :schema => 'schema',
                :host => 'host',
                :port => 'port'
            }
        }

        YAML.stub!( :load ).and_return(@db)

        @config = DeploymentConfiguration.new
        #uri = config.connection_string_from_properties(@db[:database])

        uri = 'postgres://localhost:5432/CAT_STAGING?user=mistest&password=password'

        #expectations for SqlExtractor
        @mock_sql_extract = mock( 'sql_extract' )
        SqlExtractor.should_receive(:new).once.with(uri).and_return(@mock_sql_extract)

        @sql_extract_driver = SqlDriver.new uri
    end

    it 'should dump the data extract in a file' do
        #prepare
        options = { :environment => 'sandbox', :schema => 'public', :source_table => 'source_table' }
        @mock_sql_extract.should_receive(:extract).once.with(options)
        @mock_sql_extract.should_receive(:dataset).and_return(@dataset)

        #act
        @sql_extract_driver.extract(options).should eql(@dataset)
    end

    it 'should write the data to a dump file' do

        columns = ['col1', 'col2']
        expected_columns = columns + ['environment']
        
        #expectations for database
        @mock_database = mock('database')
        Database.should_receive(:new).and_return(@mock_database)
        @mock_database.should_receive( :schema= ).once.with( any_args )
        @mock_database.should_receive( :get_column_metadata ).once.with( 'table_name' ).and_return( columns )

        #expectations for ObjectToCsvFileTransform
        @mock_csv_transformation = mock('csv_transformation')
        @mock_csv_transformation.should_receive(:transform).once.with( @dataset, :mapping => expected_columns )

        #act
        @sql_extract_driver.transform( @mock_csv_transformation, 'table_name', @dataset, @config.database )
    end
    
    it 'should pass the options to the transformer if supplied' do
        columns = ['col1', 'col2']
        expected_columns = columns + ['environment']
        options = { :worksheet => 'worksheet.xls' }
        #expectations for ObjectToCsvFileTransform
        @mock_csv_transformation = mock('csv_transformation')
        @mock_csv_transformation.should_receive(:transform).once.with( @dataset, 
                                :mapping => options.merge({:meta_data => expected_columns}) )
        
        #stub to get column meta data
        @sql_extract_driver.stub!(:load_column_name_meta_data_for_table).and_return(expected_columns)

        #act
        @sql_extract_driver.transform( @mock_csv_transformation, 'table_name', @dataset, @config.database, options )
    end
    
    it "should extract data from a dataset" do
        #setup
        expected_columns = []
        dataset = mock( 'dataset' )
        @mock_transformer = mock('transformer')

        #expectations
        [1,2].each do |idx|
            col = mock( "col#{idx}" )
            col.should_receive( :name ).and_return( "col#{idx}" )
            expected_columns.push( col )
        end
        dataset.should_receive( :columns ).and_return( expected_columns )
        @mock_transformer.should_receive(:transform).once.with( dataset, :mapping => ['col1', 'col2'] )

        #act
        @sql_extract_driver.transform_dataset( @mock_transformer, dataset, nil )
    end
end
