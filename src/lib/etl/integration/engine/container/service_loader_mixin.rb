# #!/usr/bin/env ruby

require "rubygems"

include MIS::Framework

module ETL
    module Integration
        module Engine
            module Container
                # Mixin providing support for dynamic runtime loading of
                # DSL service definitions from .service(.rb) files.
                module ServiceLoaderMixin

                    include ServiceExecutionEnvironmentSupport

                    def services()
                        @services ||= []
                    end

                    # Loads the code in the <i>file</i> into the current context.
                    def load(file)
                        if file.starts_with? '.'
                            bootstrap_path = File.dirname(self.context().config.bootstrap_file)
                            file = File.join(bootstrap_path, File.basename(file))
                        end
                        source_code = load_script_resource(file) # does *safe* IO
                        load_service(file, source_code)
                    end

                    # Loads the supplied <code>source_code</code> into the system.
                    def load_service(file, source_code)
                        begin
                            _info("Loading service definitions from #{file}.")
                            precompiler = ServicePrecompiler.new(file, source_code)
                            precompiler.precompile()
                            clean_source_code = precompiler.get_modified_source_code()
                            class_def = define_class(classname="#{file}ServiceBuilder", superclazz=ServiceConfigurationBuilder)
                            class_def.add_method_def(methodname='configure',sourcecode=clean_source_code)
                            service_builder = class_def.compile()
                            resolved = service_builder.build(self.context())
                            services.push(service_builder)
                            return resolved
                        rescue Exception => ex
                            _debug(ex.message, ex)
                        end
                    end

                end
            end
        end
    end
end
