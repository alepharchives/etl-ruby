#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'
include BehaviourSupport
include ETL

module ETL
    module Mock
        class Mailer
            def self.deliver_send_message(to, sender, subject, body_text)
                puts "To:#{to}, Sender:#{sender}"
            end
        end
    end
end

describe ProcessMonitor do
    
    before :each do
        @config_hash = {
            :monitoring => {
                :admins => 'admin',
                :remote_user => 'user',
                :remote_server => 'server',
                :remote_port => 23,
                :remote_directory => 'remote_dir',
                :local_directory => 'local_dir'
            },
            :sender => 'sender'
        }
        File.stub!( :open ).and_return( nil )
        YAML.stub!( :load ).and_return(@config_hash)
        @config = DeploymentConfiguration.new
        
        @file_names = ['file_a', 'file_b']
        @monitor = ProcessMonitor.new(@config, @file_names, ETL::Mock::Mailer)
    end
    
    it "should download data files from the remote server" do        
        @monitor.should_receive(:download_data_files).with(@config_hash.monitoring.remote_user, 
            @config_hash.monitoring.remote_server, 
            @config_hash.monitoring.remote_port, 
            @config_hash.monitoring.remote_directory, 
            @config_hash.monitoring.local_directory)
        @monitor.stub!(:validate_files_and_send_email)
        @monitor.start
    end
    
    it 'should validate files downloaded from the remote server' do
        @monitor.stub!(:download_data_files)

        @file_names.each do |file|
            File.should_receive(:file?).with(file).and_return(true)
        end
                                                                        
        @monitor.start
    end
    
    it 'should send email if any file is missing' do
        @monitor.stub!(:download_data_files)
        File.stub!(:file?).and_return(false)
        expected_subject = 'MIS Alarm'
        expected_body_text = 'File: file_a not found.'
        
        ETL::Mock::Mailer.should_receive(:deliver_send_message).with(@config_hash.monitoring.admins,
                                                                  @config_hash.sender, expected_subject, expected_body_text)
        @monitor.start
    end
    
end

