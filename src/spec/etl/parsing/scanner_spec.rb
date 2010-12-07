#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'

include BehaviourSupport
include ETL::Parsing

describe given( Scanner ), 'when tokenizing a string' do

    it 'should use whitespace as the boundary between tokens' do
        #setup
        input_string = "  foo bar baz "
        scanner = Parser::Scanner.new( input_string )

        expected_tokens = [ 'foo', 'bar', 'baz' ]
        until scanner.eos?
            scanner.next_token.should eql( expected_tokens.shift )
        end
    end

    it 'should tokenize the values on any supplied delimiters' do
        input_string = 'foo bar (bubba) baz (flobby)[]{floo}%%'
        scanner = Parser::Scanner.new( input_string )
        scanner.options = {
            :custom_delimiters => {
                /\(/ => /\)|$/,
                /\[/ => /\]|$/,
                /\{/ => /\}|$/,
                /\%/ => /\s|$/
            }
        }

        expected_tokens = [ 'foo', 'bar', '(bubba)', 'baz', '(flobby)', '[]', '{floo}', '%%' ]
        until scanner.eos?
            scanner.next_token.should eql( expected_tokens.shift )
        end
    end

    it 'should give custom delimiters precedence over whitespace when tokenizing' do
        input = "input one some.custom.string.i.want.to.collect([sip:foobar@baz.com, input two"
        scanner = Parser::Scanner.new( input,
            :custom_delimiters => {
                /[\w\.]*(?=\(\[)/ => /.*,/
            }
        )

        expected_tokens = [ 'input', 'one', 'some.custom.string.i.want.to.collect([sip:foobar@baz.com,', 'input', 'two' ]
        until scanner.eos?
            scanner.next_token.should eql( expected_tokens.shift )
        end
    end

end
