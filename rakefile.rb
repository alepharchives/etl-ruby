#!/usr/bin/env ruby

ENV['STARTUP_PATH'] = File.dirname( __FILE__ ) unless ENV['STARTUP_PATH']

require 'rubygems'
path = File.expand_path( File.dirname( __FILE__ ) )

# require path + '/prereqs'

require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'fileutils'
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'
require 'src/spec/spec_helper'
require 'sql/rakefile'

import 'test/rakefile.rb'

include FileUtils

$spec_out_directory = nil
$rcov_out_directory = nil
$integration_out_directory = nil

def launder_paths( iterable )
    iterable.collect do |elemenent|
        File.expand_path elemenent
    end
end

ROOT_DIR        = File.expand_path( File.dirname( __FILE__ ) )
OUPUT_PATH      = 'target'
DISTRIBUTION_PATH = 'dist'
CLEAN.include( OUPUT_PATH )
CLEAN.include( DISTRIBUTION_PATH )

# NB: many of our test cases have been deleted prior to publication
task :default => [ :unit_test ] #, :sql_unit_test, :integration_tests ]

desc "Setting global configuration options"
task :set_global_conf do
    out_directory =
        if ENV['CC_BUILD_ARTIFACTS']
        ENV['CC_BUILD_ARTIFACTS']
    else
        File.dirname( __FILE__ ) + '/target'
    end
    _info("Setting output directory to '#{out_directory}'.")
    $spec_out_directory = out_directory + '/test_results'
    $rcov_out_directory = out_directory + '/coverage'
    $integration_out_directory = out_directory + '/integration_test_results'

    mkdir out_directory, :verbose => true unless File.directory? out_directory
    mkdir $spec_out_directory, :verbose => true unless File.directory? $spec_out_directory
    mkdir $rcov_out_directory, :verbose => true unless File.directory? $rcov_out_directory
    mkdir $integration_out_directory, :verbose => true unless File.directory? $integration_out_directory

    puts "Removing the generated newworkbook files"
    rm_rf "newworkbook.*.xls"
    _info("Setting spec out directory to #{$spec_out_directory}.")    
end

#------------------------------------------------------------------------------
# Unit Tests
#------------------------------------------------------------------------------

desc 'Run all ruby unit tests'
task :unit_test => :set_global_conf do
    Spec::Rake::SpecTask.new('unit_test') do |task|
        task.spec_files = FileList['src/spec/**/*.rb']
        task.spec_opts = [ "--format html:#{$spec_out_directory}/index.html --format specdoc" ]
        task.rcov = true
        task.rcov_opts = [ '-T', '--xrefs', '-x /spec/*' ]
        task.rcov_dir = $rcov_out_directory
    end

    cmd = 'mv ' + File.dirname( __FILE__ ) + '/sql_spec_index.html ' + $spec_out_directory
    system cmd
end

RCov::VerifyTask.new( :code_coverage => :unit_test ) do |task|
    out_directory =
        if ENV['CC_BUILD_ARTIFACTS']
        ENV['CC_BUILD_ARTIFACTS']
    else
        File.dirname( __FILE__ ) + '/target'
    end
    _info("Setting output directory to '#{out_directory}'.")
    task.index_html = out_directory + '/coverage/index.html'
    task.threshold = $config.code_coverage_threshold
    task.require_exact_threshold = false
end

#------------------------------------------------------------------------------
# Database unit/integration Tests
#------------------------------------------------------------------------------
#desc "Run all sql/db tests - drops and creates fresh database"
#task :sql_unit_test do
#    Spec::Rake::SpecTask.new('sql_unit_test') do |task|
#        task.spec_files = FileList['sql/spec/**/*.rb']
#        task.spec_opts = [ "--format html:sql_spec_index.html --format specdoc" ]
#    end
#    Spec::Rake::SpecTask.new('drop_sql_unit_test_database')
#end

#------------------------------------------------------------------------------
# Packaging task(s)
#------------------------------------------------------------------------------

# GEM INFO

# The gem name
PKG_NAME        = "etl4r"
# The current version number (to build with)
PKG_VERSION     = "1.3.0"

# PACKAGE CONTENT

# The output folder for all packaged stuff
PKG_OUTPUT      = "#{File.expand_path( DISTRIBUTION_PATH )}"
# The directory containing the ruby source we want to distribute
PKG_RUBY_SRC    = FileList[ 'src/lib/**/*.rb' ]
# The plugins directory
PLUGIN_DIR      = 'plugins'
# The list of database scripts we need to deploy
DB_SCRIPTS      = 'sql/lib'
# The project directory containing deployable scripts
PROJECT_SCRIPT_DIR = "#{File.dirname( __FILE__ )}/../scripts"
# The list of shell scripts to be deployed
DEPLOYMENT_ARTIFACTS   = FileList[
    "#{PROJECT_SCRIPT_DIR}/*.yml",
    "#{PROJECT_SCRIPT_DIR}/staging*.sh",
    "#{PROJECT_SCRIPT_DIR}/**/*workflow*.rb"
]

# A list of all log analysis grammars
GRAMMARS = FileList[ 'grammar/*.grammar', 'grammar/*.grammar' ]
# A list of all log analysis transformation algorithms
TRANSFORMERS = FileList[ 'transformers/*.transformer' ]
# A list of all default services
SERVICES = FileList[ 'services/*.service', 'services/*.service.rb' ] #NB: No recursing into subdirectories!

# PACKAGE STRUCTURE

# The deployment directory containing scripts, configuration and grammars
DEPLOYMENT_DIR    = "#{PKG_OUTPUT}/deployment"
# The deployment directory containing shell scripts to be deployed
DEPLOYMENT_SCRIPTS_DIR = DEPLOYMENT_DIR
# The deployment directory containing sql scripts to be deployed
DEPLOYMENT_DB_SCRIPTS_DIR = "#{DEPLOYMENT_DIR}/db_scripts"
# The deployment directory containing the log analys grammars
DEPLOYMENT_GRAMMAR_DIR = "#{DEPLOYMENT_DIR}/grammar"
# The deployment directory containing the log analys transformation algorithms
DEPLOYMENT_TRANSFORMER_DIR = "#{DEPLOYMENT_DIR}/transformers"
# The deployment directory containing the default services
DEPLOYMENT_SERVICE_DIR = "#{DEPLOYMENT_DIR}/services"

task :create_distribution_directory do
    # HACK: to get around windows file system permissions issues
    attempts = 0
    begin
        puts "retrying rm -rf #{PKG_OUTPUT} ... attempt ##{attempts}" if attempts > 1
        rm_rf PKG_OUTPUT, :verbose => true if File.directory? PKG_OUTPUT
    rescue SystemCallError
        raise StandardError, $! if attempts > 150
        attempts += 1
        retry
    end
    [
        PKG_OUTPUT,
        DEPLOYMENT_DIR,
        DEPLOYMENT_DB_SCRIPTS_DIR,
        DEPLOYMENT_GRAMMAR_DIR
    ].each do |target_dir|
        mkdir target_dir, :verbose => true
    end
end

task :package_for_deployment => :create_distribution_directory do
    DEPLOYMENT_ARTIFACTS.each { |file| cp file, DEPLOYMENT_DIR, :verbose => true }
    cp_r DB_SCRIPTS, DEPLOYMENT_DB_SCRIPTS_DIR, :verbose => true
    GRAMMARS.each { |file| cp file, DEPLOYMENT_GRAMMAR_DIR, :verbose => true }
    TRANSFORMERS.each { |file| cp file, DEPLOYMENT_TRANSFORMER_DIR, :verbose => true }
    SERVICES.each { |file| cp file, DEPLOYMENT_SERVICE_DIR, :verbose => true }
end

task :uninstall do
    puts "uninstalling gem #{PKG_NAME} "
    cmd = "gem uninstall #{PKG_NAME}"
    system cmd
end

task :install do
    puts "installing gem #{PKG_OUTPUT}/#{PKG_NAME}-#{PKG_VERSION}.gem"
    cmd = "gem install #{PKG_OUTPUT}/#{PKG_NAME}-#{PKG_VERSION}.gem"
    system cmd
end

spec = Gem::Specification.new do |spec|
    spec.name = PKG_NAME
    spec.version = PKG_VERSION
    spec.description = <<-EOF
        etl4r is an Extract Transform Load framework
    EOF

    spec.author = "Web21c MIS Team"
    spec.files = PKG_RUBY_SRC
    spec.require_path = 'src/lib'
    spec.has_rdoc = false
    spec.autorequire = 'etl'
    spec.add_dependency 'postgres-pr', '>= 0.4.0'
    spec.required_ruby_version = '>= 1.8.6'
    #spec.bindir = 'bin'
    #spec.executables = ['etl', 'etl_build_generator']
    #spec.default_executable = 'spec'
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.package_dir = PKG_OUTPUT
    #pkg.need_zip = true
    #pkg.need_tar = true
end

task :install_gem => [:uninstall, :build, :install]
task :build_gem => [:package]
task :build => [ :package_for_deployment, :package ]
