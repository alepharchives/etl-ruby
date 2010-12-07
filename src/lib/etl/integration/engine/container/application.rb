# #!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Container
                class Application

                    include ServiceLoaderMixin
                    include Validation

                    # Gets the execution context for this application.
                    attr_reader :context

                    def initialize(config_file=nil)
                        @context = ExecutionContext.new(config_file)
                    end

                    def start(command_expression=nil)
                        config = @context.config
                        if command_expression.nil?
                            bootstrap(config.bootstrap_file)
                            verify_entry_point()
                            @watcher = FileWatcher.new(config.landing_dir, config[:watch_sleep_timeout])
                            @watcher.on_created( &method( :on_file_created ) )
                            @watcher.start()
                        else
                            bootstrap(config.bootstrap_file)
                            bootstrapper = bootstrap_code(command_expression)
                            if bootstrapper.respond_to? :marshal
                                @entry_point = bootstrapper
                            elsif bootstrapper.respond_to? :process
                                @entry_point = ProcessorEndpoint.new("etl://entry-point", @context, bootstrapper)
                            else
                                #TODO: a test case for this....
                                raise ClassLoadException.new("Unknown (dynamically loaded code)",
                                    "Expression #{command_expression} failed to resolve to an endpoint.")
                            end
                            run()
                        end
                    end

                    def stop()
                        @watcher.stop() unless @watcher.nil?
                    end

                    protected

                    def bootstrap(file)
                        load(file)
                    end

                    def bootstrap_code(code)
                        load_service("'bootstrap (command line interface)'", code)
                    end

                    def verify_entry_point()
                        @entry_point = @context.lookup_uri(@context.config.entry_point)
                    end

                    def on_file_created(file)
                        #TODO: consider passing the *signal* in to the constructor
                        return unless file =~ /\.completed/
                        run()
                    end

                    def run()
                        @entry_point.marshal(create_outbound_message())
                    end

                    private

                    def create_outbound_message()
                        message = Message.new
                        message.set_header(:event, :new_data)
                        message.set_header(:uri, URI.parse("lfs:/#{@context.config.landing_dir}"))
                        exchange = Exchange.new(@context)
                        exchange.inbound = message
                        return exchange
                    end

                end
            end
        end
    end

end
