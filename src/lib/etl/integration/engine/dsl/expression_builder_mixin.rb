#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module DSL
                # Provides integrated support for defining #Expression objects
                # using our internal DSL syntax
                module ExpressionBuilderMixin

                    private

                    @@truthExpression = Lang::Expression.new { true }
                    @@falsehoodExpression = Lang::Expression.new { false }
                    @@bodyExpression = Lang::Expression.new { |exchange| exchange.inbound.body }

                    public

                    # where(expr) -> expr
                    #
                    # Syntactic sugar for <code>expression</code>.
                    def where(expression)
                        raise ex=InvalidExpressionException.new(expression), ex.message, caller() unless expression.respond_to?(:evaluate)
                        return expression
                    end

                    # Returns an #Expression which is 'always' true
                    def always()
                        @@truthExpression
                    end

                    # Returns an #Expression which is 'never' true
                    def never()
                        @@falsehoodExpression
                    end

                    # Returns an #Expression which negates the supplied <param>expression</param>.
                    def negate(expression)
                        on_invalid_expression(expression) unless expression.respond_to? :evaluate
                        Lang::Expression.new { |exchange| !(expression.evaluate(exchange)) }
                    end

                    alias_method :unless, :negate
                    
                    # Returns an #Expression which resolves the body of an inbound message exchange.
                    def body()
                        @@bodyExpression
                    end

                    # Returns a #HeaderExpression for the given header name.
                    def header(headername)
                        return HeaderExpression.new(headername)
                    end

                    def method_missing(sym, *args)
                        return super if args.size > 0
                        return header(sym)
                    end

                    private

                    def on_invalid_expression(expression)
                        raise InvalidExpressionException.new(expression),
                            "An expression must respond to 'evaluate' to be negated.", caller
                    end

                end
            end
        end
    end
end
