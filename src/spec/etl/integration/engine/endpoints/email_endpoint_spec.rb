# #!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../../../../spec_helper'

include BehaviourSupport
include MIS::Engine

# ##################################################################################### ##############
# Behaviour Examples                    ################
# #####################################################################################

describe given( ETL::Integration::Engine::Endpoints::EmailEndpoint ), 'when initializing a new instance' do

    it_should_behave_like "All tested constructor behaviour"

    before :all do
        @clazz = EmailEndpoint
        @constructor_args = [ 'mailer' ]
    end    
end

describe given( ETL::Integration::Engine::Endpoints::FileEndpoint ), 'when pulling exchanges out of an endpoint' do

    it_should_behave_like "All tested constructor behaviour"

    before :each do
        @clazz = EmailEndpoint
        @constructor_args = [ 'mailer' ]
        
        @mock_email_service = duck
        @email_endpoint = @clazz.new(@mock_email_service)
    end    
    
    it "should pass the correct arguments to EmailService" do
        args = get_email_arguments()
        
        @mock_email_service.should_receive(:deliver_send_message).with(args[:to], args[:sender], args[:subject], 
            args[:file_names], args[:body_text])
        
        @email_endpoint.deliver_report(args[:to], args[:sender], args[:subject], args[:file_names], args[:body_text])
    end    
    
    [:to, :sender, :file_names].each do |key|
        it 'should throw an exception if #{key} are not provided' do
            args = get_email_arguments()

            args[key] = nil
            lambda {
                @email_endpoint.deliver_report(args[:to], args[:sender], args[:subject], args[:file_names], args[:body_text])
            }.should raise_error(ArgumentError, "#{key} not valid")
        end
    end
    
    it 'should throw an exception if mailer does not respond to send_message' do
        class MailerDouble
            
        end
        lambda {
            email_endpoint = @clazz.new(MailerDouble.new)
            args = get_email_arguments()
            email_endpoint.deliver_report(args[:to], args[:sender], args[:subject], args[:file_names], args[:body_text])
        }.should raise_error(StandardError, "Mailer should define send_message")
    end
        
    private
    
    def get_email_arguments
        {
            :to => 'to', 
            :sender => 'sender', 
            :subject => 'subject',
            :file_names => ['file1', 'file2'], 
            :body_text => 'body_text'     
        }
    end
    
end

