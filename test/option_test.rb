require 'minitest/autorun'
require 'minitest/pride'
require_relative 'test_helpers.rb'
require_relative '../lib/option.rb'

describe Option::Lexer do

  include Option::Lexer, TestHelpers::TestPrograms

  before do
    @empty_program = get_test_program("empty_program")
    @simple_program = get_test_program("simple_program")
    @nested_program = get_test_program("nested_program")
    @simple_arrays_program = get_test_program("simple_arrays_program")
  end

  it "ignores_extraneous characters" do
    Option::Lexer.tokenize(@empty_program).must_equal []
  end

  it "raises_exception_when_invariants_do_not_hold" do
    proc {Option::Lexer.tokenize(@simple_program)}
      .wont_be_instance_of Option::Lexer::InvariantError
  end

  it "simple program" do
    Option::Lexer.tokenize(@simple_program).must_equal [
      [:SYMBOL, 'name'],
      [:WHITESPACE, 1],
      [:STRING, 'John Doe'],
      [:NEWLINE, 0],
      [:SYMBOL, 'age'],
      [:WHITESPACE, 3],
      [:NUMBER, '19'],
      [:EOP]]
  end

  it "nested programs" do
    Option::Lexer.tokenize(@nested_program).must_equal [
      [:SYMBOL, 'pilot'],
      [:INDENT, 1],
      [:SYMBOL, 'name'],
      [:WHITESPACE, 1],
      [:STRING, 'John Doe'],
      [:OUTDENT, 0],
      [:SYMBOL, 'co-pilot'],
      [:INDENT, 1],
      [:SYMBOL, 'name'],
      [:WHITESPACE, 1],
      [:STRING, 'Joanna Dole'],
      [:NEWLINE, 2],
      [:SYMBOL, 'age'],
      [:WHITESPACE, 1],
      [:NUMBER, "32"],
      [:EOP]]
  end

  it "has simple arrays" do
    Option::Lexer.tokenize(@simple_arrays_program).must_equal [
      [:SYMBOL, "crew"],
      [:WHITESPACE, 1],
      [:STRING, "John Doe"],
      [:COMMA],
      [:NEWLINE, 5],
      [:STRING, "Joanna Dole"],
      [:NEWLINE, 5],
      [:STRING, "Jules Dancer"],
      [:NEWLINE, 0],
      [:SYMBOL, "ages"],
      [:WHITESPACE, 1],
      [:NUMBER, "42"],
      [:COMMA],
      [:WHITESPACE, 1],
      [:NUMBER, "32"],
      [:EOP]]
  end
end
