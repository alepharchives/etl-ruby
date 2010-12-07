#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module SQL
            module PostgreSqlAdapter

                include ErrorHandlerMixin                
                
                @@driver_has_been_loaded = false

                private
                def load_driver
                    unless @@driver_has_been_loaded
                        begin
                            require 'postgres'
                            @@driver_has_been_loaded = true
                        rescue LoadError
                            raise StandardError, "No postgres driver available: #{$!}'"
                        end
                    end
                    @callbacks = []
                end

                public

                def auto_commit_transactions=( setting )
                    if setting
                        @transaction_strategy = AutoCommitTransactionStrategy.new self
                    else
                        @transaction_strategy = ManualCommitTransactionStrategy.new self
                    end
                end

                def auto_commit_transactions
                    @transaction_strategy.instance_of? AutoCommitTransactionStrategy
                end
                
                alias auto_commit? auto_commit_transactions
                
                def connection_string
                    "postgres://#{@host}:#{@port}/#{@catalog}?user=#{@user}&password=#{@pass}"
                end                

                [:begin, :commit, :rollback].each do | cmd |
                    class_eval(<<-CODE
                        def #{cmd.to_s}_transaction
                            execute '#{cmd.to_s};'
                        end
                    CODE
                    )
                end

                #
                # Fires 'sql' at the database and returns a ResultSet object. Raises DataAccessException if anything goes wrong.
                #
                def execute( sql, backwards_compat=false )
                    result = @conn.query( sql )
                    if backwards_compat
                        return PGresult.new( result )
                    else
                        ResultSet.new result
                    end
                rescue Exception => e
                    raise DataAccessException.new( e.message, e ), $!, caller
                end
                
                # 
                # Executes 'sql' and returns the first column of the first row in the result set returned by the query. 
                # All other columns are ignored. Multiple rows will cause an InvalidOperationException to be raised. 
                # If the underlying rowset is empty, this method will return nil. Raises DataAccessException if anything goes wrong.
                #
                def execute_scalar( sql )
                    resultset = execute( sql )
                    return nil unless resultset.rowcount > 0
                    raise InvalidOperationException.new( "excecute_scalar can not return multiple rows" ) if resultset.rowcount > 1
                    return resultset.rows.first.send( resultset.columns.first.name.to_sym )
                end

                # Just like it says.
                def connect()
                    begin
                        raise InvalidOperationException, 'connection is already open' unless @conn.nil?
                        load_driver
                        uri =
                        if @host.nil?
                          nil
                        elsif running_on_windows
                            "tcp://#{ @host }:#{ @port }"
                        else
                            "tcp://#{ @host }:#{ @port }"
                            #"unix:#{ @host }/.s.PGSQL.#{ @port }"
                        end
                        @conn = PostgresPR::Connection.new( @catalog, @user, @pass, uri )                        
                    rescue Exception => ex
                        on_connect_error( ex, self )
                    end
                end

                alias open connect

                # Is it, or not!?
                def connected?
                    !@conn.nil?
                end

                # The opposite of connect. :p
                def disconnect()
                    @callbacks.each { |block| block.call }.clear()
                    @conn.close if @conn
                    @conn = nil
                end

                alias close disconnect

                #
                # Performs a series of operations transactionally and yields control to the
                # supplied &block. If auto_commit_transactions is set to true, each statement
                # will be executed in its own transaction, otherwise the whole block is executed within
                # one transaction, which is committed (by default) at the end of the block.
                #
                # With auto_commit_transactions set to false, any exception(s) raised while the block
                # is executing will cause the entire transaction to roll back.
                #
                def perform( &block )
                    @transaction_strategy.perform( &block )
                end

                def register_shutdown_callback( &block )
                    @callbacks.push block
                end

                private
                
                def launder_runtime_error( ex )
                    message_match = ex.message.match( /(ERROR|FATAL|WARNING)(?:[\s]+)([\w]*)(?:[\s]+)(.*)/ )
                    [ 'severity', 'error_code', 'message' ].each do |error_part|
                        
                    end
                end
                
                def build_connectivity_exception( error_code=:C01000, severity=:WARNING, cause=nil )
                    ex = ConnectivityException.new( self.connection_string, 
                            error_message( error_code, ex.message ), cause )
                    ex.error_code = error_code
                    ex.severity = severity
                end
                
                def error_message( error_code, message_body )
                    "#{error_code}: #{message_body}"
                end
                
                class AutoCommitTransactionStrategy
                    def initialize driver
                        @driver = driver
                    end
                    def execute command #TODO: what is this for? ... ???
                        @driver.execute command
                    end
                    def perform( &block )
                        raise InvalidOperationException, 'no block given!' unless block
                        begin
                            if block.arity != 0
                                yield @driver
                            else
                                yield
                            end
                        rescue Exception => ex
                            raise DataAccessException.new( $!, ex ), $!, caller
                        end
                    end
                end

                class ManualCommitTransactionStrategy < AutoCommitTransactionStrategy
                    def initialize driver
                        super
                    end
                    def perform( &block )
                        #todo: think about how remove this irksome duplication
                        raise InvalidOperationException, 'no block given!' unless block
                        @driver.begin_transaction
                        begin
                            super
                            @driver.commit_transaction
                        rescue DataAccessException => ex
                            @driver.rollback_transaction
                            raise ex, ex.message, caller
                        end
                    end
                end

            end
        end
    end
end
