#!/usr/bin/env ruby
 
require 'rubygems'
require File.dirname(__FILE__) + "/../../spec_helper"

class ClassWithImmutableAttributeReader
    immutable_attr_reader :items
    def initialize(items)
        @items = items
    end
end

describe "Attribute reader immutable lookup methods" do
    
    it "should return a duplicate of the lookup, not the original object" do
        items = %w(foo bar baz)
        sut = ClassWithImmutableAttributeReader.new(items)
        item_lists_are_equivalent_but_not_equal(items, sut.items).should be_true
    end
    
    it "should freeze the resulting clone" do
        ClassWithImmutableAttributeReader.new((1..10)).items.should be_frozen
    end
    
    def item_lists_are_equivalent_but_not_equal(first, second)
        return false if first.object_id.eql?(second.object_id)
        return first.eql?(second)
    end
    
end

describe "Class initialization extension methods" do

    it "should allow a consumer class to specify the argument list for its ctor declaratively" do
        class Person
            initialize_with :name, :age, :validate => true
        end
        lambda do
            Person.new(nil, nil)
        end.should raise_error( ArgumentError, "the 'name' argument cannot be nil" )
    end

    it 'should initialize all supplied arguments properly' do
        class AnotherPerson
            initialize_with :name, :age, :attr_reader => true
        end
        expected_name = 'Tim'
        expected_age = 2891
        person = Person.new( expected_name, expected_age )
        person.instance_eval { @name }.should eql( expected_name )
        person.instance_eval { @age }.should eql( expected_age )
    end

    it 'should set attribute reader when specified by the caller' do
        class Human
            initialize_with :name, :age, :gender, :attr_reader => true
        end
        person = Human.new( 'foo', 116, :male )
        person.respond_to?( :name ).should be_true
        person.respond_to?( :age ).should be_true
    end

    it 'should set attribute writer when specified by the caller' do
        class Snafu
            initialize_with :situation, :description, :expletive, :attr_writer => true
        end
        sit_rep = Snafu.new( 'situation normal', 'all ok dude', 'none whatsoever!' )
        [ :situation=, :description=, :expletive= ].each do |sym|
            sit_rep.respond_to?( sym ).should be_true
        end
    end

    it 'should raise an error if any *named arguments* are supplied' do
        lambda do
            class Exploding
                initialize_with :foo => true, :bar => false
            end
        end.should raise_error( ArgumentError )
    end

    it 'should validate the presence of any required arguments' do
        class Vampire
            initialize_with :fangs, :strength, :validate => true
        end
        dracula = nil
        lambda do
            dracula = Vampire.new nil, 10
        end.should raise_error( ArgumentError, "the 'fangs' argument cannot be nil" )
    end

    it 'should pass validated arguments on to the original initailizer' do
        class Egg
            initialize_with :free_range, :size, :yolk, :attr_reader => true, :validate => true
            alias free_range? free_range
        end
        egg = Egg.new( true, :large, :yummy )
        egg.free_range.should be_true
        egg.size.should eql( :large )
        egg.yolk.should eql( :yummy )
    end

    it 'should use a custom validator if supplied' do
        class Fool
            initialize_with :name, :foolishness, :attr_reader => true do |fool|
                raise ArgumentError, "#{fool.foolishness} is not foolish enough!" unless fool.foolishness > 10
            end
        end
        lambda do
            Fool.new( "motley ", 9 )
        end.should raise_error( ArgumentError, "9 is not foolish enough!" )
    end
    
    it "should explode if you pass the wrong number of arguments" do
	class ClassWithTwoArgCtor
	    initialize_with :name, :age
        end
	lambda {
	    ClassWithTwoArgCtor.new('hello there, I am the first argument!', 20384, "WHAT! Another Argument? That's gotta explode right!?")
        }.should raise_error(ArgumentError, "wrong number of arguments (3 for 2)")
    end    

end
