#!/usr/bin/env ruby

require 'rubygems'
source_directory = File.dirname( __FILE__ )
#require File.expand_path( source_directory + '/../prereqs' )
require 'rake'
require 'rake/clean'
require 'fileutils'
require 'spec/rake/spectask'

require File.expand_path( source_directory + '/../src/spec/spec_helper' )

import source_directory + '/remote/rakefile.rb'

include FileUtils

#destination_folder = File.expand_path( "#{source_directory}/lib" )

#------------------------------------------------------------------------------
# ETL Pipeline integration tests
#------------------------------------------------------------------------------

desc "Clean test data dump directory"
task :clean_test_dump => :set_global_conf do
    dump = File.expand_path 'test/integration/data/dump'

    # HACK: to get around windows file system permissions issues - doesn't seemd
    # =>    to effect unix based systems at all though.
    attempts = 0
    begin
        puts "retrying rm -rf #{dump} ... attempt ##{attempts}" if attempts > 1
        rm_rf dump, :verbose => true
        mkdir dump, :verbose => true
    rescue SystemCallError
        #raise StandardError, $! if attempts > 25
        attempts += 1
        retry
    end
end

desc "Reset global configuration"
task :reset_global_conf => :clean_test_dump do
    original_startup = ENV['STARTUP_PATH']
    ENV['STARTUP_PATH'] = File.dirname( __FILE__ )
    _info("Resetting 'STARTUP_PATH' environment variable from #{original_startup} to #{ENV['STARTUP_PATH']}.")
    $config = ETL::DeploymentConfiguration.new
end

desc "Run remote extract integration tests"
task :remote_extract_integration_tests => [ :reset_global_conf, :build_local_chit, :build_local_conf ] do
    Spec::Rake::SpecTask.new('remote_extract_integration_tests') do |task|
        task.spec_files = FileList[ source_directory + '/remote/*spec.rb' ]
        task.spec_opts = [ "--format specdoc" ]
    end
end

#desc "Workflow specific integration tests"
#task :workflow_integration_tests => [ :reset_global_conf ] do
#    # NB: the ordering of these FileLists is very important. Remote must run first, then pipeline then dataload!
#    Spec::Rake::SpecTask.new( 'integration_tests' ) do |task|
#        task.spec_files =
#            FileList[ File.expand_path( 'test/integration/ruby/workflow/*spec.rb' ) ]
#        task.spec_opts = [ "--format html:#{$integration_out_directory}/index.html --format specdoc" ]
#    end
#end

desc "All Integration Tests"
task :integration_tests => [ :reset_global_conf, :build_database ] do 
    # NB: the ordering of these FileLists is very important. Remote must run first, then pipeline then dataload!
    Spec::Rake::SpecTask.new( 'integration_tests' ) do |task|
        task.spec_files =
            FileList[ File.expand_path( 'test/integration/ruby/dataload/*spec.rb' ) ] +
            FileList[ File.expand_path( 'test/integration/ruby/exclusions/*spec.rb' ) ] +
            #            #Need to run migration_spec so that it transforms the raw data.
            FileList[ File.expand_path( 'test/integration/ruby/sql/*spec.rb' ) ] +
            FileList[ File.expand_path( 'test/integration/ruby/pipeline/old_session_transform_spec.rb' ) ] +
            FileList[ File.expand_path( 'test/integration/ruby/pipeline/new_session_transform_spec.rb' ) ] +
            FileList[ File.expand_path( 'test/integration/ruby/pipeline/callflow_*_transform_spec.rb' ) ] +
            FileList[ File.expand_path( 'test/integration/ruby/pipeline/application_registration_transform_spec.rb' ) ] +
            FileList[ File.expand_path( 'test/integration/ruby/pipeline/integration_ldif_transform_spec.rb' ) ] +
            FileList[ File.expand_path( 'test/integration/ruby/pipeline/chit_transform_spec.rb' ) ] +
            FileList[ File.expand_path( 'test/integration/ruby/pipeline/messaging_transform_spec.rb' ) ] +
            FileList[ File.expand_path( 'test/integration/ruby/workflow/*spec.rb' ) ]
        task.spec_opts = [ "--format html:#{$integration_out_directory}/index.html --format specdoc" ]
    end
end

# task :default => [:integration_tests, :remote_extract_integration_tests]

#desc "Test ETL pipeline integration"
#task :pipeline_integration_tests => :remote_extract_integration_tests do
#    Spec::Rake::SpecTask.new('pipeline_integration_tests') do |task|
#        task.spec_files = FileList[ File.expand_path( 'test/integration/ruby/pipeline/*spec.rb' ) ]
#        task.spec_opts = [ "--format specdoc" ]
#    end
#end
#
#desc "Test Dataload integration"
#task :dataload_integration_tests => :pipeline_integration_tests do
#    Spec::Rake::SpecTask.new('dataload_integration_tests') do |task|
#        task.spec_files = FileList[ File.expand_path( 'test/integration/ruby/dataload/*spec.rb' ) ]
#        task.spec_opts = [ "--format specdoc" ]
#    end
#end

#desc "All Integration Tests"
#task :integration_tests => [ :unit_test, :sql_unit_test, :reset_global_conf, :build_database ] do
#    # NB: the ordering of these FileLists is very important. Remote must run first, then pipeline then dataload!
#    Spec::Rake::SpecTask.new( 'integration_tests' ) do |task|
#        task.spec_files = FileList[source_directory + '/remote/*spec.rb'] +
#            FileList[ File.expand_path( 'test/integration/ruby/pipeline/*spec.rb' ) ] +
#            FileList[ File.expand_path( 'test/integration/ruby/dataload/*spec.rb' ) ] +
#            # Need to run migration_spec so that it transforms the raw data.
#            FileList[ File.expand_path( 'test/integration/sql/migration_spec.rb' ) ] +
#            FileList[ File.expand_path( 'test/integration/sql/*.rb' ) ].exclude('**/migration_spec.rb')
#        task.spec_opts = [ "--format html:#{$integration_out_directory}/index.html --format specdoc" ]
#    end
#end
