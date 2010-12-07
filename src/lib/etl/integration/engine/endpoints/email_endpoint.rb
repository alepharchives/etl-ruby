#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module Endpoints
                
                class EmailEndpoint

                    include Validation
                    
                    def initialize(mailer)
                        validate_arguments(binding()) 
                        raise StandardError, "Mailer should define send_message", caller unless mailer.respond_to? :deliver
                        @mailer = mailer
                    end
                    
                    def deliver_report(to ,sender, subject, file_names, body_text)
                        validate_email_arguments({:to => to, :sender => sender, :subject => subject, 
                                                                :file_names => file_names, :body_text => body_text })
                        @mailer.deliver_send_message(to ,sender, subject, file_names, body_text)
                    end
                    
                    private
                    
                    def validate_email_arguments(args)
                        [:to, :sender, :file_names].each do |key|
                            raise ArgumentError, "#{key} not valid", caller if args[key].nil?
                        end
                    end        
                end
            end
        end
    end
end