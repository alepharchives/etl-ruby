#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module Processors

                # A generic exchange processing task for use in #Pipline(s).
                # A #Processor can be initialized with a block, in which case this block
                # forms the implementation part of the #process template method.
                #
                # Alternatively, subclasses can override the abstract (in fact, undefined!)
                # <code>do_process</code> method and implement their own functionality in it.
                # #process calls into #do_process within a begin, rescue block and therefore ensures
                # that any unhandled exceptions get turned into fault messages. Subclasses therefore,
                # should not overly concern themselves with exception handling or validation code.
                #
                # If a #Hash of options is supplied to a #Processor(s) constructor, then these
                # will be used to automatically set headers in the outbound (and fault) channels
                # upon completion.
                #
                # <example>
                # <code>
                # Processor.new(
                #   :header1 => 'some value',
                #   :header2 => Expression.new { |exchange| return exchange.inbound.headers.has_key?(:header1) }, # NB this is evaluated lazily
                #   :header3 => '${my_field_name}'
                # ) do |exchange|
                #   # ... add your code here...
                #   @my_field_name = 'some value' # this will be put into the outbound headers automatically.
                # end
                # </code>
                # </example>
                #
                # In this trivial example, the first header is automatically set to a predefined
                # value (e.g. an object). The second header is set to an #Expression object - when
                # this happens, the #Expression will be (lazily) evaluated (using #Expression#evaluate) on the
                # #Exchange passed to #Processor#process.
                #
                # Finally, the third header is set to a string whose format describes a simple expression
                # langage for processors, which can be used to simplify handling output data and response
                # management generally.
                #
                # Internal expressions are set by supplying a default header key with a string value formatted
                # like so: <code>expr = "${field_name_goes_in_here}"</code>.
                #
                # Like the #Expression API in #ETL::Integration::Engine::DSL, this <i>expression language</i>
                # is internal to its container (i.e. this class). The #Processor instances handling of this expression
                # language is also similar to that of #Expression object instances, in that both are lazily evaluated
                # each time the #process method is called.
                #
                class Processor
                    
                    include ETL::Integration::Engine::RuntimeSupportMixin

                    # Initializes each instance of the #Processor class.
                    # The supplied block is used during calls to #process
                    def initialize(options={}, &processing_block)
                        define_do_process(&processing_block) unless processing_block.nil?
                        @options = options ||= {}
                    end

                    # Processes the supplied exchange.
                    # If the processing block raises an exception, a suitable fault is
                    # passed to the exchange's fault channel.
                    def process(exchange)
                        #TODO: consider NotImplementedException instead?
                        raise NoMethodError unless self.respond_to?(:do_process)
                        begin
                            reset_options()
                            #NOTE: not thread safe and also a 'method object' might read easier...
                            @current_exchange = exchange
                            _debug("Processing exchange from [#{origin(exchange)}].")
                            do_process(exchange)
                        rescue Exception => ex
                            fault = Message.new
                            fault.set_header(:fault_code, @options[:fault_code]||FaultCodes::UnhandledException)
                            fault.set_header(:fault_description, ex.message||$!)
                            fault.set_header(:exception, ex)
                            fault.set_header(:inbound_message, exchange.inbound)
                            fault.set_header(:context, self)
                            exchange.fault = fault
                        ensure
                            force_outbound(exchange)
                            process_options(exchange)
                            @current_exchange = nil
                        end
                    end

                    protected

                    # Gets the body from the inbound message channel of the supplied <i>exchange</i>
                    def body(exchange)
                        return exchange.inbound.body
                    end

                    # Sets a header in the outbound message channel of the supplied exchange, using
                    # the specified <code>header_name</code> and <code>value</code>.
                    def set_outbound_header(exchange, header_name, value)
                        if internal_expression_language?(value)
                            value = instance_variable_get(fieldname(value))
                        elsif value.kind_of?(Expression) || value.respond_to?(:evaluate)
                            value = value.evaluate(exchange)
                        end
                        force_outbound(exchange)
                        exchange.outbound.set_header(header_name, value)
                    end

                    # Synonym for #set_outbound_header
                    alias outheader set_outbound_header

                    # Gets the header specified in <code>header_name</code> from the
                    # inbound message channel of the current exchange (within the context of a call to
                    # #process) and returns it.
                    #
                    # If the header is not present and <code>throw_if_missing</code> is true, raises
                    # #InvalidPayloadException.
                    def inheader(header_name, throw_if_missing=false)
                        header_value = @current_exchange.inbound.headers[header_name]
                        if header_value.nil? && throw_if_missing
                            on_invalid_payload(@current_exchange, "Header #{header_name} has not been specified in the message headers.")
                        end
                        return header_value
                    end

                    def on_invalid_payload(exchange, message)
                        @options[:fault_code] = FaultCodes::InvalidPayload
                        raise InvalidPayloadException.new(self, exchange), message, caller
                    end

                    private

                    def define_do_process(&processing_block)
                        #TODO: this next few lines of code cause RCOV 0.8.1.2.0 to explode when calling create_cross_refs
                        mixin = Module.new
                        mixin.send(:define_method, :do_process, &processing_block)
                        self.extend(mixin)
                    end

                    def force_outbound(exchange)
                        exchange.outbound = Message.new if exchange.outbound.nil?
                    end

                    def process_options(exchange)
                        force_outbound(exchange)
                        unless @options.nil?
                            @options.each do |header_name, value|
                                if header_name.eql?(:body) && value.eql?(true)
                                    exchange.outbound.body = body(exchange)
                                else
                                    set_outbound_header(exchange, header_name, value)
                                end
                            end
                        end
                        preset_keys = exchange.outbound.headers.keys
                        unless exchange.inbound.nil?
                            exchange.inbound.headers.each do |key, value|
                                set_outbound_header(exchange, key, value) unless preset_keys.include?(key.to_sym)
                            end
                        end
                    end

                    def reset_options()
                        unless @options.nil?
                            @options.each do |header_name, value|
                                if internal_expression_language?(value)
                                    instance_variable_set(fieldname(value), nil) unless value.nil?
                                end
                            end
                        end
                    end

                    def internal_expression_language?(value)
                        return false if value.nil?
                        if value.kind_of?(String)
                            return value[/\$\{.*\}/]
                        end
                        return false
                    end

                    def fieldname(value)
                        raise ArgumentError, "Cannot get back a fieldname for 'nil'.", caller() if value.nil?
                        fieldname = value.match(/\$\{(.*)\}/)[1]
                        fieldname = "@#{fieldname}" unless fieldname.starts_with? "@"
                    end
                end
            end
        end
    end
end
