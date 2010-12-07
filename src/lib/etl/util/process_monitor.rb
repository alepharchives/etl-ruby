#!/usr/bin/env ruby

require 'rubygems'

module ETL 
    class ProcessMonitor
        @data_files = []
        @monitoring_config = nil
        @sender = nil
        @mailer_class = nil
    
        def initialize(config, file_names, mailer_class)
            @sender = config.sender
            @monitoring_config = config.monitoring
            @data_files = file_names
            @mailer_class = mailer_class
        end
    
        def start
            download_data_files(@monitoring_config.remote_user, @monitoring_config.remote_server, 
                @monitoring_config.remote_port, @monitoring_config.remote_directory, 
                @monitoring_config.local_directory)
            validate_files_and_send_email(@data_files, @monitoring_config.admins, @sender)
        end
    
        private
    
        def validate_files_and_send_email(filenames, recipients, sender)
            filenames.each do |file_name|
                unless File.file? file_name
                    message = "File: #{file_name} not found."
                    @mailer_class.deliver_send_message(recipients, sender, 'MIS Alarm', message)
                    return
                end
            end
        end

        def download_data_files(user, server, port, source, destination)    
            @data_files.each do |file|
                system "sftp -oPort=#{port} #{user}@#{server}:#{source}/#{file} #{destination}"
            end
        end
    end
end