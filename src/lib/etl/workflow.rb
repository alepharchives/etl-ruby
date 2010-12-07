#!/usr/bin/env ruby

require "rubygems"
 
include MIS::Framework
include MIS::Engine

module MIS
    module Workflow
        include ETL::Integration::Engine::DSL::ExpressionBuilderMixin
        include ETL::Integration::Engine::DSL::ProcessorSupportMixin
        include ETL::Integration::Engine::DSL::BuilderSupportMixin   
        include ETL::Integration::Engine::Container::ServiceLoaderMixin        
    end
end
