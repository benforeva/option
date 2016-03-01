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
    @complex_nested_program = get_test_program("complex_nested_program.on")
    @simple_arrays_program = get_test_program("simple_arrays_program")
    @complex_arrays_program = get_test_program("complex_arrays_program.on")
    @packages = get_test_program("packages.on")
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
      [:APPLY, 1],
      [:STRING_LIM],
      [:STRING, 'John Doe'],
      [:STRING_LIM],
      [:NEWLINE, 0],
      [:SYMBOL, 'age'],
      [:APPLY, 3],
      [:NUMBER, '19'],
      [:EOP]]
  end

  it "nested programs" do
    Option::Lexer.tokenize(@nested_program).must_equal [
      [:SYMBOL, 'pilot'],
      [:INDENT, 1],
      [:SYMBOL, 'name'],
      [:APPLY, 1],
      [:STRING_LIM],
      [:STRING, 'John Doe'],
      [:STRING_LIM],
      [:OUTDENT, 0],
      [:SYMBOL, 'co-pilot'],
      [:INDENT, 1],
      [:SYMBOL, 'name'],
      [:APPLY, 1],
      [:STRING_LIM],
      [:STRING, 'Joanna Dole'],
      [:STRING_LIM],
      [:NEWLINE, 2],
      [:SYMBOL, 'age'],
      [:APPLY, 1],
      [:NUMBER, "32"],
      [:EOP]]
  end

  it "has simple arrays" do
    Option::Lexer.tokenize(@simple_arrays_program).must_equal [
      [:SYMBOL, "crew"],
      [:APPLY, 1],
      [:STRING_LIM],
      [:STRING, "John Doe"],
      [:STRING_LIM],
      [:COMMA, 0],
      [:NEWLINE, 5],
      [:STRING_LIM],
      [:STRING, "Joanna Dole"],
      [:STRING_LIM],
      [:NEWLINE, 5],
      [:STRING_LIM],
      [:STRING, "Jules Dancer"],
      [:STRING_LIM],
      [:NEWLINE, 0],
      [:SYMBOL, "ages"],
      [:APPLY, 1],
      [:NUMBER, "42"],
      [:COMMA, 1],
      [:NUMBER, "32"],
      [:EOP]]
  end

  it "has complex arays" do
    Option::Lexer.tokenize(@complex_arrays_program).must_equal [
      [:SYMBOL, "array"],
      [:APPLY, 1],
      [:NUMBER, "234"],
      [:NEWLINE, 6],
      [:SYMBOL, "fname"],
      [:APPLY, 1],
      [:STRING_LIM],
      [:STRING, "Tinu"],
      [:STRING_LIM],
      [:NEWLINE, 6],
      [:SYMBOL, "lname"],
      [:APPLY, 1],
      [:STRING_LIM],
      [:STRING, "Elejogun"],
      [:STRING_LIM],
      [:NEWLINE, 0],
      [:NEWLINE, 6],
      [:SYMBOL, "&sum"],
      [:APPLY, 1],
      [:NUMBER, "5"],
      [:COMMA, 1],
      [:NUMBER, "34"],
      [:COMMA, 1],
      [:NUMBER, "27"],
      [:NEWLINE, 0],
      [:SYMBOL, "string"],
      [:APPLY, 1],
      [:STRING_LIM],
      [:STRING, "natural"],
      [:STRING_LIM],
      [:EOP]
    ]
  end

end
