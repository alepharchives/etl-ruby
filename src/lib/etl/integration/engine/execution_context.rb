#!/usr/bin/env ruby

require "rubygems"


module ETL
    module Integration
        module Engine
            # Provides a runtime execution context, service registry
            # and configuration store for the integration engine.
            class ExecutionContext

                attr_writer :default_fault_channel

                def initialize(configfile=nil)
                    @config = DeploymentConfiguration.new(configfile)
                    @endpoint_mappings = {}
                end

                # Gets the deployment configuration properties for this instance.
                def config()
                    return @config
                end

                def default_fault_channel
                    @default_fault_channel ||= DefaultErrorChannel.new
                end

                alias properties config

                # Checks to see if <code>uri</code> has already been registered.
                def registered?(uri)
                    uri = sanitize_uri(uri)
                    return @endpoint_mappings.has_key?(uri)
                end

                # Performs a lookup against the specified uri.
                #
                # <code>uri</code> can be a string or an instance or <code>URI</code>.
                #
                # For a standardized uri (such as postgres, file or lfs), the endpoint
                # will always be cached. For an internal uri (e.g. 'etl://host/path'),
                # endpoints are cached but may be duplicated. Any endpoint returned by
                # this method may actually be a transparent proxy for the underlying endpoint.
                #
                # <b><u>Lookups against <i>ETL</i> uris</u></b>
                #
                # An internal uri can be resolved only if the corresponding service has been
                # registered first (otherwise a #ServiceNotFoundException will be raised).
                # To distinguish between services, pipelines and processors (registered as a
                # service), use an api conversion modifier in the query string.
                #
                # For example, to convert an #Endpoint (or #Service) to a processor, you would
                # use the following code (assuming that you have a valid, loaded context and the
                # endpoint or service has already been registered):
                #
                # <code>
                # processorForEndpoint =
                #       context.lookup_uri("#{targeturi}?api=process")
                # </code>
                #
                # To create a pipeline processor, you would perform the same lookup (pipelines get
                # special handling here) and obtaining a consumer doesn't require an API conversion,
                # as consumers are registered under the correct API anyway.
                #
                def lookup_uri(uri)
                    uri = sanitize_uri(uri)
                    endpoint = lookup_endpoint(uri)

                    return endpoint unless endpoint.nil?

                    #TODO: consider whether ServiceNotFoundException is a better choice...?
                    raise UnresolvableUriException.new(uri) if uri.scheme.eql?('etl')
                    case uri.scheme
                    when 'postgres'
                        endpoint = DatabaseEndpoint.new(uri, self)
                    when 'lfs'
                        endpoint = DirectoryEndpoint.new(uri, self)
                    when 'file'
                        endpoint = FileEndpoint.new(uri, self)
                    end
                    register(uri, endpoint)
                    return endpoint
                end

                # Gets a frozen copy of the registered services and endpoints in this context.
                def endpoints
                    return @endpoint_mappings.values.dup.freeze
                end

                # Registers the specified endpoint with the context.
                #
                # Raises #ArgumentError unless the endpoint responds to both
                # the producer and consumer api calls (unmarshal and marshal,
                # respectively)
                #
                def register_endpoint(endpoint)
                    [ :unmarshal, :marshal ].each do |required_method|
                        invalid_endpoint_registration(required_method, "An endpoint", endpoint) unless endpoint.respond_to? required_method
                    end
                    register(endpoint.uri, endpoint)
                end

                # Registers the specified service with the context.
                #
                # Raises #ArgumentError unless the endpoint responds to both
                # the producer api (e.g. :unmarshal)
                #
                def register_service(service)
                    invalid_endpoint_registration(:marshal, "A service", service) unless service.respond_to? :marshal
                    register(service.uri, service)
                end

                # Registers the supplied pipeline processor and its internal pipeline as a
                # process and service (respectively).
                #
                # Pipelines are registered based on their internal uri, and can be retrieved directly
                # using this (via #lookup_uri). A pipeline processor can be obtained by appending the
                # path '/processor' to the pipeline's own uri when performing a lookup.
                #
                # Raises #ArgumentError unless the pipeline processor responds to :pipeline
                # and the pipeline responds to the producer api (e.g. :unmarshal)
                #
                def register_pipeline(pipelineProcessor)
                    invalid_endpoint_registration(:process, "A pipeline processor", pipelineProcessor) unless pipelineProcessor.respond_to? :process
                    invalid_endpoint_registration(:pipeline, "A pipeline processor", pipelineProcessor) unless pipelineProcessor.respond_to? :pipeline
                    register(pipelineProcessor.uri, pipelineProcessor)
                    register_service(pipelineProcessor.pipeline)
                end

                # Registers the supplied pipeline consumer.
                def register_consumer(consumer)
                    invalid_endpoint_registration(:process, "A consumer", consumer) unless consumer.respond_to? :process
                    register(consumer.uri, consumer)
                end
                
#                def endpoint_conversion(endpoint, interface, uri_minus_query="anonymous")
#                    case interface
#                    when :process
#                        return lookup_endpoint(sanitize_uri("#{uri_minus_query}/processor")) if endpoint.kind_of?(Pipeline)
#                        return EndpointProcessor.new(endpoint) if endpoint.respond_to?(:marshal)
#                    when :marshal
#                        if endpoint.respond_to?(:process)
#                            return ProcessorEndpoint.new("#{uri_minus_query}/processor", self, endpoint)
#                        end
#                    end
#                    invalid_api_conversion(interface, uri) unless endpoint.respond_to? interface
#                end
                
                private

                def sanitize_uri(uri)
                    uri = URI.parse(uri) if uri.kind_of? String
                    #TODO: write a test for this (next line)...
                    #return sanitize_uri(uri.uri) if uri.respond_to?(:uri)
                    return uri
                end

                def lookup_endpoint(uri)
                    uri = sanitize_uri(uri)
                    uri_minus_query = uri.dup
                    uri_minus_query.query = nil
                    return nil unless @endpoint_mappings.has_key? uri_minus_query

                    endpoint = @endpoint_mappings[uri_minus_query]
                    if (uri.query || '').include?('api=')
                        interface = uri.query.split('=').second.to_sym
                        case interface
                        when :process
                            return lookup_endpoint(sanitize_uri("#{uri_minus_query}/processor")) if endpoint.kind_of?(Pipeline)
                            return EndpointProcessor.new(endpoint) if endpoint.respond_to?(:marshal)
                        when :marshal
                            if endpoint.respond_to?(:process)
                                return ProcessorEndpoint.new("#{uri_minus_query}/processor", self, endpoint)
                            end
                        end
                        invalid_api_conversion(interface, uri) unless endpoint.respond_to? interface
                    end
                    return endpoint
                end

                def register(uri, endpoint)
                    uri = sanitize_uri(uri)
                    uri_minus_query = uri.dup
                    uri_minus_query.query = nil
                    raise InvalidOperationException, "The uri '#{uri}' has already been registered.", caller if @endpoint_mappings.has_key? uri_minus_query
                    _info("Registered endpoint [#{endpoint.class}] for uri '#{uri}'.")
                    @endpoint_mappings.store(uri_minus_query, endpoint)
                end

                def invalid_endpoint_registration(methodname, descriptor="An endpoint", endpoint=nil)
                    unless endpoint.nil?
                        if endpoint.kind_of?(String)
                            uri = endpoint
                        else
                            uri = endpoint.respond_to?(:uri) ? endpoint.uri : "Unknown uri."
                        end
                        _debug("Registration failed for '#{endpoint.class}' on uri '#{uri}'.")
                    end
                    raise EndpointRegistrationException.new(
                        self, message="#{descriptor} must respond to '#{methodname}' to be eligable for registration.",
                        endpoint,
                        uri
                    ), message, caller()
                end

                def invalid_api_conversion(interface, uri)
                    raise ServiceNotFoundException.new(
                        message="The api conversion '#{interface}' failed.", self, uri), message, caller
                end

            end
        end
    end
end
