#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../spec_helper'

include MIS::Framework

describe FileWatcher, 'when creating a new file watcher' do

    before :all do
      @dummy_dir_name = '/home/abc'
      @invalid_dir_name = '/home/invalid/'
    end

    it 'should throw error if directory is not specified' do
        lambda do
            FileWatcher.new
        end.should raise_error(ArgumentError)
    end

    it 'should initialize the directory' do
      File.should_receive(:directory?).once.with(@dummy_dir_name).and_return(true)
      f = FileWatcher.new @dummy_dir_name
      f.directory.should eql(@dummy_dir_name)
    end

    it 'should not be able to change the directory' do
        lambda do
            File.should_receive(:directory?).once.with(@dummy_dir_name).and_return(true)
            f = FileWatcher.new @dummy_dir_name
            f.directory = 'abc'
        end.should raise_error(NoMethodError)
    end

    it 'should initialize the sleep time to 10 when sleep time not specified' do
        File.should_receive(:directory?).once.with(@dummy_dir_name).and_return(true)
        f = FileWatcher.new @dummy_dir_name
        f.sleep_time.should eql(10)
    end

    [5, 10, 15].each do |expected_sleep_time|
      it 'should initialize the sleep time' do
          File.should_receive(:directory?).once.with(@dummy_dir_name).and_return(true)
          f = FileWatcher.new @dummy_dir_name, expected_sleep_time
          f.sleep_time.should eql(expected_sleep_time)
      end
    end

    [-1, 0, 'ABC'].each do |invalid_sleep_time|
      it 'should initialize the sleep time to 10 when sleep time specified is invalid (-1, 0, Big Number)' do
          File.should_receive(:directory?).once.with(@dummy_dir_name).and_return(true)
          f = FileWatcher.new @dummy_dir_name, invalid_sleep_time
          f.sleep_time.should eql(10)
      end
    end

    it 'should throw error if specified directory does not exist' do
        File.should_receive(:directory?).once.with(@invalid_dir_name).and_return(false)
        lambda do
            f = FileWatcher.new @invalid_dir_name
        end.should raise_error(ArgumentError, sprintf("%s is not a valid directory", @invalid_dir_name))
    end

end

describe FileWatcher, 'when starting a file watcher on a valid directory' do

    before :all do
        @valid_dir_name = '/home/nauman/temp/tmp'
        @new_file = 'newfile'
        @modified_file = 'i_have_changed'
        @deleted_file = 'i_have_been_deleted'
    end

    #NOTE: Nauman/Leanne => Trying to fake out the File, FileTest, and various FSWatcher classes is tough!
    #                       I'm taking a less robust but easier approach, to get our code coverage threshold above 90%.

    it 'should notify when a new file is created' do
        setup_expectations @new_file, FileSystemWatcher::CREATED
        f = FileWatcher.new @valid_dir_name
        f.on_created do |file|
            #NB: this isn't a very tight expectation => we forced @new_file to appear.
            #   my rationale here is that we're trying to prove the block get's called, but
            #   it's not a true integration test.
            file.should eql( @new_file )
        end

        f.start
        f.stop
    end

    it 'should notify when a file is modified' do
        setup_expectations @modified_file, FileSystemWatcher::MODIFIED
        f = FileWatcher.new @valid_dir_name
        f.on_modified do |file|
            #NB: this isn't a very tight expectation => we forced @modified_file to appear.
            #   my rationale here is that we're trying to prove the block get's called, but
            #   it's not a true integration test.
            file.should eql( @modified_file )
        end

        f.start
        f.stop
    end

    it 'should not notify when a file is deleted' do
        setup_expectations 'some_file', FileSystemWatcher::DELETED
        f = FileWatcher.new @valid_dir_name
        f.on_created { |file| raise StandardError, "shouldn't execute the block!" }
        f.on_modified { |file| raise StandardError, "shouldn't execute the block!" }
        lambda do
            f.start
            f.stop
        end.should_not raise_error
    end

    def setup_expectations filename, fsw_status
        File.should_receive(:directory?).once.with( @valid_dir_name ).and_return( true )
        file_path = sprintf( '%s/%s', @valid_dir_name, filename )

        mock_fsw = mock 'file system watcher'
        mock_fsw.should_receive( :addDirectory ).once.with( @valid_dir_name )
        mock_fsw.should_receive( :sleepTime= ).once.with( 10 )
        mock_fsw.should_receive( :start ).once.and_yield( fsw_status, filename )
        mock_fsw.should_receive( :stop ).once
        FileSystemWatcher.stub!( :new ).and_return( mock_fsw )
    end

end
