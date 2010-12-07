#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Container
                # Acts like a class loader for a given #ExecutionContext (which
                # in this case, is acting as a container).
                class ServiceLoader
                end
            end
        end
    end
end

=begin

## start dsl code

require "rubygems"

include MIS::Workflow

load('loghandlers.service.rb')
load('someother.service.rb')

pipeline("etl://foo").from("directory1").via(consume("etl://loghandlers")).to("dumpdir")

## end dsl code

module ????

    def services()
        @services ||= []
    end

    def load(script_uri)
        source_code = load_script_resource(file) # does *safe* IO
        precompiler = ServicePrecompiler.new(file, source_code)
        precompiler.precompile()
        clean_source_code = precompiler.get_modified_source_code()
        class_def = define_class(classname="#{clean_filename(file)}ServiceBuilder", superclazz=ServiceConfigurationBuilder)
        class_def.add_method_def(methodname='configure',sourcecode=clean_source_code)
        serviceBuilder = class_def.compile()
        serviceBuilder.build(self.context())
        services.push(serviceBuilder)        
    end

end

class ServiceLoader

    include ServiceExecutionEnvironmentSupport

    def initialize(source_directory, config_directory)
	local_variables.each { |var| instance_variable_set("@#{var}", eval(var)) }
    end

    def load
	Dir.glob("#{@source_directory}/**/*.rb").each do |file|
	    source_code = load_script_resource(file) # does *safe* IO

	    class_def = define_class(classname="#{clean_filename(file)}ServiceBuilder", superclazz=ServiceConfigurationBuilder)
	    class_def.add_method_def(methodname='configure',sourcecode=source_code)
	    @services.push(class_def.compile())
	end
    end

    

    def deploy(context)
	@services.each do |service_builder|
	    service_builder.build(context)
	end
    end

end

=end