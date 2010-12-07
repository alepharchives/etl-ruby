#!/usr/bin/env ruby

require 'rubygems'

module MIS
    module Framework
        include ETL
        include ETL::Integration
        include ETL::Integration::IO
        include ETL::Integration::SQL
        include ETL::Integration::Extraction
        include ETL::Parsing
        include ETL::Transformation
        include ETL::Transformation::Pipeline
        include ETL::Transformation::Pipeline::Filters
        include ETL::Subjects
        include ETL::Subjects::Usage
        include ETL::Subjects::Usage::Filters
        #include ETL::Subjects::Identity
        include ETL::Commands
        include ETL::Commands::FileSystem
        include ETL::Commands::Transformation
    end
end
