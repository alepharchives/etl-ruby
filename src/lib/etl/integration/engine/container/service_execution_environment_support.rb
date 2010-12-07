#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Container
                protected

                # Provides utility methods for internal use by the execution environment.
                module ServiceExecutionEnvironmentSupport

                    # A utility used to define classes.
                    class ClassDef
                        attr_accessor :class_name, :class_ancestors, :method_defs
                        def initialize()
                            @method_defs = []
                        end
                        def add_method_def(method_name, source_code)
                            methodDef = MethodDef.new
                            methodDef.method_name = method_name
                            methodDef.source_code = source_code
                            @method_defs.push(methodDef)
                            return methodDef
                        end
                        def compile()
                            clazz = Class.new(self.class_ancestors)
                            method_defs.each do |methodDef|
                                code=<<-CODE
                                    def #{methodDef.method_name}
                                        #{methodDef.source_code}
                                    end
                                CODE
                                clazz.module_eval(code)
                            end
                            return clazz.new
                        end
                        def eql?(other)
                            return self.class_name.eql?(other.class_name) &&
                                self.class_ancestors.eql?(other.class_ancestors)
                        end
                    end

                    # A structure used to store the definition of methods on classes.
                    MethodDef = Struct.new("MethodDef", :method_name, :source_code)

                    # Creates a new #ClassDef instance and sets the class name and ancestors.
                    def define_class(class_name, superclazz=Object)
                        clazzDef = ClassDef.new
                        clazzDef.class_name = class_name
                        clazzDef.class_ancestors = superclazz
                        return clazzDef
                    end

                    def load_script_resource(file_uri)
                        file_uri = sanitize_filename(file_uri)
                        source = File.read(file_uri)
                        unless source.size > 0
                            raise ClassLoadException.new(file_uri, "Source code is tainted! Check your $SAFE level...")
                        end
                        return source
                    end

                    private

                    def sanitize_filename(filename)
                        return filename if File.exist? filename
                        unless File.extname(filename).eql?('.service')
                            filename = "#{filename}.service"
                            return filename if File.exist? filename
                        end
                        filename = "#{filename}.rb"
                        return filename if File.exist? filename
                        return nil
                    end

                    # Helps to define classes and modules at runtime...
                    module ModuleDefinitionLoader

                        def dynamic_module_define(const, &block)
                            self.class.const_set(const, Module.new)
                            clazz = self.class.const_get(const)
                            clazz.module_eval(&block) unless block.nil?
                        end

                        def dynamic_class_define(const, superclass=nil, &block)
                            self.class.const_set(const, Class.new(superclass || Object))
                            clazz = self.class.const_get(const)
                            clazz.module_eval(&block) unless block.nil?
                        end

                    end

                end
            end
        end
    end
end
