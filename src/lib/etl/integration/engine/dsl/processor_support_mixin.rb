#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module DSL
                # Provides DSL methods for top level workflow declaration(s).
                module ProcessorSupportMixin

                    # Gets a listener for the supplied uri, which responds to 'marshal'.
                    def listener(uri)
                        return @context.lookup_uri("#{uri}?api=marshal")
                    end
                    
                    # Looks up a processor for the supplied pipeline uri.
                    #
                    # This message is provided a special case for looking up a
                    # #PipelineProcessor with which to execute a pre-defined #Pipeline
                    # instance (e.g. one that already has a 'from' and a 'to' uri in
                    # place - as opposed to a #PipelineConsumer, which doesn't know anything
                    # about its source ('from') uri at build time.
                    #
                    # This message corresponds to the the call <code>lookup_uri</code> on an
                    # #ExecutionContext, passing an API conversion requirement in the query string.
                    # 
                    # NB: service registry lookups against a pipeline uri will always return either
                    # the pipeline itself, or a pipeline processor (see #ExecutionContext#lookup_uri for
                    # further details). To obtain a pipeline consumer, send the #consume message instead.
                    # 
                    def execute(uri)
                        #TODO: how the heck will this work prior to registration!? Duh!
                        return @context.lookup_uri("#{uri}?api=process")
                    end
                    
                    # Looks up a consumer (e.g. #PipelineConsumer) for the supplied uri.
                    # 
                    # #PipelineConsumer(s) are an easy case to imagine, as they're registered
                    # directly with the context and therefore the uri lookup will succeed without 
                    # requiring any API conversion (because #PipelineConsumer is a subclass of #Processor).
                    #
                    # A more interesting case would be consuming an endpoint (or service) directly,
                    # which looks up an #EndpointProcessor for the given target uri.
                    #
                    def consume(uri)
                        #TODO: how the heck will this work prior to registration!? Duh!                        
                        consumer = @context.lookup_uri(uri + "?api=process")
                        raise InvalidOperationException, "Consumers must respond to process.", caller unless consumer.respond_to? :process
                        return consumer
                    end
                    
                    alias process consume
                    
                    # Creates a redirect evaluator (e.g. an instance of #RouteBuilder) and
                    # evaluates the supplied block against it, returning the builder's product
                    # afterwards.
                    #
                    # Redirects take a 'where' clause to define the routing condition, and 
                    # a destination 'to' uri which defines the target endpoint. If any 'via' 
                    # steps are added then the target endpoint implicitly becomes a pipeline 
                    # consumer and different steps are taken.
                    # 
                    # <code>
                    #   # here is a simple redirect
                    #   redirect do
                    #       where(header(:basename).matches(/foo/)).to(destination)
                    #   end
                    #   
                    #   # here we will add some 'via' steps to our redirect specification
                    #   redirect do
                    #       # this next line implicitly creates pipeline consumer...
                    #       where(condition1).via(step1, step2).to(destination)
                    #   end
                    #   
                    #   # here is the equivalent to the code immediately above, when declared
                    #   # inline as a consumer and references in the 'to' clause of a redirect.
                    #   consumer("etl://myconsumer").via(step1, step2).to(destination)
                    #   
                    #   # ... and the redirect...
                    #   redirect.where(condition1).to("etl://myconsumer")
                    #   
                    # </code>
                    #
                    def redirect(&block)
                        builder = RouteBuilder.new(context())
                        builder.instance_eval(&block)
                        return builder.product()
                    end
                    
                    # Creates a new #Splitter over the given destination. If <code>destination</code>
                    # is a #Builder, then it will be built first. If <code>destination</code> is a #URI
                    # instance (or a uri-string) then it will be resolved first. 
                    #
                    # Finally, the #Splitter instance is initialized and returned.
                    # 
                    # Can be used in <code>to</code> and <code>from</code> directives, or as part of a 
                    # clause that needs to resolve to an endpoint.
                    def splitter(destination)
                        #puts "splitting #{destination}"
                        #TODO: maybe duck typed checks would be better instead!?
                        if destination.kind_of?(Builder)
                            visitor = ServiceBuilderVisitor.new(context())
                            destination.accept_visitor(visitor)
                            return splitter(destination.uri)
                        end
                        unless destination.kind_of?(Endpoint)
                            endpoint = context().lookup_uri(destination)
                            return Splitter.new(endpoint, context())
                        end
                    end
                    
                    # Provides a simple mechanism to create a processor which sets the supplied headers and copies all 
                    # the inbound message settings over to the response.
                    def set_header(options)
                        return Processor.new(options.merge({:body => true})) {}
                    end
               
                end
            end
        end
    end
end
