#!/usr/bin/env ruby

require 'rubygems'
require 'log4r'



module Kernel

    DEFAULT_LOGGER_NAME = 'default'

    def default_logger()
        logger = Log4r::Logger[DEFAULT_LOGGER_NAME]
        return logger unless logger.nil?
        logger = Log4r::Logger.new(DEFAULT_LOGGER_NAME)
        logger.level = Log4r::DEBUG
        logger.additive = false
        console = Log4r::StderrOutputter.new 'console'
        logfile = Log4r::RollingFileOutputter.new('logfile',
            :filename=> "diagnostics.log",
            :maxsize => ENV['MAX_LOG_SIZE'] || ((1000 * 1000) * 50),  #kb * mb * 50
            :trunc=>false,
            :level=>Log4r::DEBUG
        )
        formatter = Log4r::PatternFormatter.new(:pattern => '%d [%l]:%m')
        [console, logfile].each do |outputter|
            outputter.formatter = formatter
        end
        logger.add('logfile')
        at_exit { log() }
        return logger
    end

    #
    # Logs the given message.
    #
    # If <code>exception</code> is given, will add an additional
    # log entry for the exception object's backtrace property.
    #
    # If <code>level</code> is given, will log at the given level
    # (defaults to 'debug').
    #
    # If <code>sender</code> is given, will attempt to get a logger for
    # <code>sender.class.to_s</code>.
    #
    def log(message=$!, level=:debug, exception=nil, sender=nil)
        if sender.respond_to?(:logger)
            logger = sender.logger
        else
            logger = default_logger()
        end
        level = :debug unless logger.respond_to?(level || :debug)
        #TODO: don't do this unless we're in debug?
        callsite = caller()[1]
        logger.send(level) { "[#{callsite}] -> #{message}" }
        logger.send(level, exception.backtrace) unless exception.nil? || exception.backtrace.nil?
    end

    [ :debug, :info, :warn, :error, :fatal ].each do |loglevel|
        code=<<-CODE
            def _#{loglevel}(message=$!, exception=nil, sender=nil)
                sender = self if sender.nil?
                log(message, :#{loglevel.to_s}, exception, sender)
            end
        CODE
        #puts code
        eval(code)
    end

#    alias default_raise raise
#
#    def raise(exception_or_ex_clazz=nil, message=nil, backtrace=nil)
#        ex_clazz = (exception_or_ex_clazz.kind_of?(Class)) ? exception_or_ex_clazz : exception_or_ex_clazz.class
#        #puts ex_clazz
#        #puts ex_clazz.ancestors
#        unless ex_clazz.ancestors.collect {|item| item.to_s }.include?('ETL::Integration::Engine')
#            return do_raise(exception_or_ex_clazz, message, backtrace)
#        end
#        begin
#            do_raise(exception_or_ex_clazz, message, backtrace)
#        rescue Exception => ex
#            #puts caller()
#            _debug("unhandled exception #{ex.class}", ex)
#            do_raise()
#        end
#    end
#
#    def do_raise(exception_or_ex_clazz, message, backtrace)
#        if [exception_or_ex_clazz, message, backtrace].detect { |obj| !obj.nil? }.nil?
#            default_raise()
#        else
#            default_raise(exception_or_ex_clazz, message, backtrace)
#        end
#    end

    def path_from_uri( uri )
        Path.new( uri )
    end

    #alias_method :context, :binding

    def eigenclass
        (class << self; self; end)
    end

    #alias_method :singleton, :eigenclass

    # Like instance_eval, expect that it takes arguments
    def instance_exec(*arguments, &block)
	name = "_bind_#{block.object_id}"
	name.succ! if self.class.send(:method_defined?, name.to_sym)
	name = name.to_sym
	begin
	    self.class.send(:define_method, name, &block)
	    self.send(name, *arguments)
	ensure
	    self.class.send(:remove_method, name) if self.class.send(:method_defined?, name)
	end
    end

    def auto_assign_locals(binding_context)
        auto_assign(binding_context, *binding_context.local_variables())
    end

    # Automatically assigned the named instance variables in
    # <code>names</code> to the current <code>self</code>.
    def auto_assign(binding_context, *names)
        names = names.collect { |name| (name.starts_with?('@')) ? name : "@#{name}" }
        locals = binding_context.local_variables.select { |varname| names.include?("@#{varname}") }
        binding_context.scope_eval do |meta_self|
            locals.each do |var|
                meta_self.send(:instance_variable_set, "@#{var}", binding_context.evaluate(var))
            end
        end
    end

    def basename(path_string)
        return path_string unless path_string.include? '/'
        return path_string[(path_string.rindex('/') + 1)..(path_string.size - 1)]
    end

    def running_on_windows #:nodoc:
        /mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM
    end

    alias running_on_windows? running_on_windows

end
