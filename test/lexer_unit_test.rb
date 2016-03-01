require 'minitest/autorun'
require 'minitest/pride'
require_relative 'test_helpers.rb'
require_relative '../lib/option.rb'

class LexerTest

  class IndentTest < MiniTest::Test
    include Lexer, TestHelpers::LexerHelper

    def test_whitespace_exactly_matches_an_indentation
      indent_count = 0
      whitespace = make_space(2)
      assert indent?(whitespace, indent_count),
        indent_error_message(whitespace, indent_count)
    end

    def test_whitespace_with_one_extra_space_matches_an_indentation
      indent_count = 0
      whitespace = make_space(3)
      assert indent?(whitespace, indent_count),
        indent_error_message(whitespace, indent_count)
    end

    def test_whitespace_with_two_extra_spaces_is_not_an_indentation
      indent_count = 0
      whitespace = make_space(4)
      refute indent?(whitespace, indent_count),
        no_indent_error_message(whitespace, indent_count)
    end

    def test_whitespace_with_too_few_spaces_is_not_an_indentation
      indent_count = 1
      whitespace = make_space(2)
      refute indent?(whitespace, indent_count),
        no_indent_error_message(whitespace, indent_count)
    end

    def test_indent_size_raises_exception_on_failure
      indent_count = 1
      assert_raises(TokenTypeError) {indent_size(make_space(2), indent_count)}
    end

    def test_indent_size_succeeds
      indent_count = 0
      whitespace = make_space(3)
      assert_equal(indent_size(whitespace, indent_count), 1)
    end
  end

  class OutdentTest < MiniTest::Test
    include Lexer, TestHelpers::LexerHelper

    def test_whitespace_exactly_matches_an_outdentation
      indent_count = 1
      whitespace = make_space
      assert outdent?(whitespace, indent_count),
        outdent_error_message(whitespace, indent_count)
    end

    def test_empty_space_matches_multilevel_outdentation
      indent_count = 2
      whitespace = make_space
      assert outdent?(whitespace, indent_count),
        outdent_error_message(whitespace, indent_count)
    end

    def test_whitespace_with_uneven_spaces_is_not_an_outdentation
      indent_count = 2
      whitespace = make_space(1)
      refute outdent?(whitespace, indent_count),
        no_outdent_error_message(whitespace, indent_count)
    end

    def test_outdent_size_not_called_with_outdent_raises_exception
      indent_count = 2
      assert_raises(TokenTypeError) {outdent_size(make_space(1), indent_count)}
    end

    def test_whitespace_matches_multilevel_outdentation
      indent_count = 3
      assert_equal(outdent_size(make_space(2), indent_count), 1)
    end
  end
end
