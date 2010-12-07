#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Container
                # <b><i>Internal Class - do not use!!!</i></b>
                class ServicePrecompiler #:nodoc:
                    # precompiles <servicename>.service.rb files, munging names and fixing class/module definitions

                    initialize_with :file, :code, :validate => true, :attr_reader => true do
                        @code = @code.dup
                    end

                    def precompile()
                        #targets = @code.scan(/(class|module)(?:[\s]+)([\w\d_]+)([^\n]*)/)
                        targets.each { |declaration| declaration.modify_member_declaration() }
                    end

                    def get_modified_source_code
                        return @code
                    end

                    class PrecompilerError < ExecutionException
                        initialize_with :declaration, :code, :file, :attr_reader => true
                    end

                    private

                    class TargetDefinition

                        include Validation

                        attr_reader :metatype, :name, :ancestor

                        def initialize(precompiler, metatype=nil, name=nil, ancestor=nil)
                            validate_arguments(binding())
                            @precompiler = precompiler
                            @metatype, @name, @ancestor = metatype, name, ancestor
                        end

                        def modify_member_declaration()
                            declaration = @precompiler.code.scan(%r'#{@type}[\s]+[\w\d_\:]+[^\n\#]+').
                                detect { |match| match.include? @name }
                            if declaration.nil?
                                raise ExecutionException, "No matching declaration found for #{@type} #{@name} in file #{@precompiler.file}"
                            end
                            @precompiler.code.gsub!(%r'#{declaration.strip}',
                                "dynamic_#{@metatype}_define(:#{@name}#{set_ancestor(declaration)}) do"
                            )
                        end

                        def set_ancestor(declaration)
                            return '' unless has_ancestor?(declaration)
                            if @ancestor[0..@ancestor.index('<')] =~ /\#/
                                on_precompiler_error(declaration)
                            end
                            match = @ancestor.match(/(?:[\s]*)(?:<{1})(?:[\s]+)([^\s#]*)/)
                            if match.nil? || match[1].nil?
                                on_precompiler_error(declaration)
                            end
                            return ", #{match[1]}"
                        end

                        def has_ancestor?(declaration)
                            return false unless @metatype.eql?('class')
                            return (@ancestor || '')[/\</]
                        end

                        def on_precompiler_error(declaration)
                            exception = PrecompilerError.new(declaration, @precompiler.code, @precompiler.file)
                            details = "in file [#{exception.file}]"
                            _debug(
                                message=(
                                (@ancestor[/\#/]) ?
                                "The declaration '#{declaration.strip}' contains comments - try removing them (#{details})." :
                                "The declaration #{declaration.strip} contains elements which the precompiler cannot process (#{details})."
                            ), exception)
                            raise( exception, message, caller() )
                        end

                    end

                    def targets()
                        return @code.scan(/(class|module)(?:[\s]+)([\w\d_]+)([^\n]*)/).
                            collect do |match_array|
                            TargetDefinition.send(:new, *([self] + match_array))
                        end
                    end

                end
            end
        end
    end
end
