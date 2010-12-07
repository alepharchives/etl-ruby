##!/usr/bin/env ruby
#
#require 'rubygems'
#require 'spec'
#
#require File.dirname(__FILE__) + '/spec_helper'
#require File.dirname(__FILE__) + '/io_commands'
#
#include BehaviourSupport
#include CommandSpecBehaviourSupport
#include ETL
#include ETL::Commands
#include ETL::Commands::Transform
#include ETL::Extractors
#
######################################################################################
###############                 Behaviour Examples                    ################
######################################################################################
#
##TODO: Somewhere in the file, a test leads to the (inappropriate) creation of a file on disk. Remove the code that does this, to protected the CI environment.
#
#describe given( LogTransformCommand ), 'when instructed to transform raw logfile data into delimited text format' do
#
#    it_should_behave_like "All I/O Dependant Commands"
#    include ClasspathResolver
#
#    before :all do
#        uri = File.expand_path( File.dirname( __FILE__ ) + '../../../../../' ) + '/config.yaml'
#        puts uri
#        @config = DeploymentConfiguration.new( uri )
#        @command_class = LogTransformCommand
#        @output_directory = @config.landing_point
#        @dummy_file_uri = File.join( @output_directory, 'dummy_file.log' )
#        File.open( @dummy_file_uri, 'w' ) { |file| }
#        @environment = 'Sandbox'
#        @expected_log_handler = 'com.xx.sdk.mis.etl.transforms.LogTransformationHandler'
#        @index = !@index.nil? ? @index + 1 : 0
#    end
#
#    it 'should make a single callout for each file' do
#        process_type = 'session'
#
#        @mock_transform = mock( 'logfile_xfrm' )
#        @mock_transform.should_receive( :transform ).once
#
#        JavaLogFilePipelineTransform.should_receive( :new ).once.with( @environment, @dummy_file_uri, @output_directory,
#            process_type, @index ).and_return( @mock_transform )
#
#        #todo catch all method invocations...
#        command = LogTransformCommand.new( @dummy_file_uri, @output_directory, @environment, process_type, @index )
#        command.execute
#    end
#
#    it 'should make multiple callouts for a group of files' do
#        process_type = 'capability_usage'
#        @mock_transform = mock( 'logfile_xfrm' )
#        file_list = [ 1, 2, 3 ].collect { |number| "file#{number}.txt" }
#        number_of_files_plus_directory_check = file_list.size + 1
#        File.should_receive( :file? ).exactly( number_of_files_plus_directory_check ).times.and_return( true )
#        JavaLogFilePipelineTransform.
#            should_receive( :new ).exactly( file_list.size ).times.
#            with( any_args ).and_return( @mock_transform )
#
#        @mock_transform.should_receive( :transform ).exactly( file_list.size ).times
#
#        command = @command_class.new file_list, @output_directory, @environment, process_type, @index
#        command.execute
#    end
#
#    it 'should wrap any underlying errors for the caller' do
#        process_type = 'session'
#
#        @mock_transform = mock( 'logfile_xfrm' )
#        @mock_transform.should_receive( :transform ).once.and_raise( TransformError )
#
#        JavaLogFilePipelineTransform.should_receive( :new ).once.with( @environment, @dummy_file_uri, @output_directory,
#            process_type, @index).and_return( @mock_transform )
#
#        lambda do
#            command = @command_class.new @dummy_file_uri, @output_directory, @environment, process_type, @index
#            command.execute
#        end.should raise_error( ProcessingError )
#    end
#
#    after :all do
#        File.delete @dummy_file_uri if File.exist? @dummy_file_uri
#    end
#
#end
#
#describe given( LdifTrasformCommand ), 'when instructed to transform raw ldif data into delimited text format' do
#
#    it_should_behave_like "All I/O Dependant Commands"
#
#    before :all do
#        @command_class = LdifTrasformCommand
#        @dummy_file_uri = 'dummy_data.ldif'
#        @dummy_destination_uri = 'ldap_data.dump'
#        @environment = 'Sandbox'
#    end
#
#    before :each do
#        File.stub!( :file? ).and_return true
#    end
#
#    it 'should delegate ldif extraction to the extractor, passing the supplied file uri' do
#        mock_extractor = mock_ldif_extractor
#        mock_extractor.should_receive( :dataset ).once.and_return( [] )
#        LdifExtractor.should_receive( :new ).once.with( @dummy_file_uri, @environment ).and_return( mock_extractor )
#        command = instantiate_command
#        command.execute
#    end
#
#    it 'should delegate file output to the transformer, passing the extracted data' do
#        test_dataset = (1..10).collect do |number|
#            DummyEntry.new( "uid#{number}", "mail#{number}", "cn#{number}" )
#        end
#        default_options = { :mapping => [ :uid, :mail, :cn ] }
#
#        mock_extractor = mock_ldif_extractor
#        mock_extractor.should_receive( :dataset ).once.and_return( test_dataset )
#        LdifExtractor.should_receive( :new ).once.with( @dummy_file_uri, @environment ).and_return( mock_extractor )
#
#        expected_delimiter = '|'
#        mock_transform = mock( 'object2csv' )
#        mock_transform.should_receive( :transform ).once.with( test_dataset, default_options )
#        ObjectToCsvFileTransform.should_receive( :new ).once.
#            with( @dummy_destination_uri, expected_delimiter ).and_return( mock_transform )
#
#        command = instantiate_command
#        command.execute default_options
#    end
#
#    it 'should wrap any underlying errors for the caller' do
#        mock_extractor = mock( 'ldif_extractor' )
#        test_message = "Test Message"
#        mock_extractor.should_receive( :extract ).once.and_raise( StandardError.new( test_message ) )
#        LdifExtractor.should_receive( :new ).once.with( @dummy_file_uri, @environment ).and_return( mock_extractor )
#        command = instantiate_command
#        lambda do
#            command.execute
#        end.should raise_error( ProcessingError, "Execution failed with StandardError: #{test_message}" )
#    end
#
#    def mock_ldif_extractor
#        mock_extractor = mock( 'ldif_extractor' )
#        mock_extractor.should_receive( :extract ).once
#        mock_extractor
#    end
#
#    # override
#    def instantiate_command( *options )
#        return @command_class.new( @dummy_file_uri, @dummy_destination_uri, @environment ) if options.nil? or options.empty?
#        options.push @environment unless options.size == 3
#        return @command_class.send( :new, *options )
#    end
#
#    after :all do
#        #File.delete( @dummy_destination_uri ) if File.exist? @dummy_destination_uri rescue Exception
#    end
#
#end
