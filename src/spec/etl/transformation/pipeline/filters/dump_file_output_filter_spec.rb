# #!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../../../")  + '/spec_helper'

include BehaviourSupport


describe DumpFileOutputFilter do
    it "should explode if supplied with a nil output writer" do
        lambda do
            DumpFileOutputFilter.new( nil )
        end.should raise_error(ArgumentError, "the 'output writer' argument cannot be nil")
    end
    
    it 'should delegate output to the writer' do
        inputArr = []
        writer = mock('writer')
        writer.should_receive(:<<).once.with(inputArr)
        filter = DumpFileOutputFilter.new writer
        
        filter.filter(inputArr, nil)
    end
    
    it 'should wrap any errors in a FilterException' do
        writer = mock('writer')
        filter = DumpFileOutputFilter.new( writer )
        writer.should_receive(:<<).once.and_raise(RuntimeError)
        
        lambda do
            filter.filter( nil, nil ) 
        end.should raise_error( FilterException )
    end
end

