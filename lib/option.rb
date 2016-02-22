module Option
  module Lexer

    TokenTypeError = Class.new(StandardError)
    InvariantError = Class.new(StandardError)

    EMPTY = ""
    WHITESPACE = " "
    COMMA = ","
    RETURN = "\r"
    NEWLINE = "\n"
    STRING_LIM = '"'
    NUMERALS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
    EOP = "..eop.."
    SPECIAL_CHARACTERS =[RETURN, NEWLINE, "\t"]
    DELIMITERS = [COMMA]
    ENDWORD = SPECIAL_CHARACTERS + [WHITESPACE]
    INDENT_INVARIANT = 0

    extend self

    def tokenize(source)
      tokens = []
      source = String.new(source)
      unless source.empty?
        tokens, chars, indent_level =
          scan(tokens, trim_program(source), INDENT_INVARIANT)
      end
      if(indent_level !=INDENT_INVARIANT || !chars.empty?)
        raise InvariantError,
          "You should never see this message. If you are, it means that "\
          "Lexical Analysis has failed for your program. Please report this "\
          "error to maintainer(s)."
      end
      return tokens
    end

    def trim_program(source)
      trimmed = source.chomp!
      trimmed.empty? ? trimmed.chars : trimmed.concat("\r").concat(EOP).chars
    end

    def scan(tokens, chars, indent_level)
      if chars.empty?
        [tokens, chars, indent_level]
      else
        chead = chars[0]
        if chead == WHITESPACE
          scan(*collect_whitespace(tokens, chars, indent_level))
        elsif DELIMITERS.include? chead
          scan(*collect_delimiters(tokens, chars, indent_level))
        elsif chead == STRING_LIM
          scan(*collect_string(tokens, chars, indent_level))
        elsif NUMERALS.include? chead
          scan(*collect_number(tokens, chars, indent_level))
        elsif chead == RETURN
          scan(*drop_return(tokens, chars, indent_level))
        elsif chead == NEWLINE
          scan(*collect_indentation(tokens, chars, indent_level))
        elsif SPECIAL_CHARACTERS.include? chead
          scan(*collect_special_characters(tokens, chars, indent_level))
        else
          scan(*collect_symbol(tokens, chars, indent_level))
        end
      end
    end

    def collect_symbol(tokens, chars, indent_level)
      sym = chars.take_while{|i| !ENDWORD.include?i}.reduce("", :<<)
      [tokens << [:SYMBOL, sym], chars.drop(sym.size), indent_level]
    end

    def collect_token_character(string, chars)
      string.concat(chars[0])
      [string, chars.drop(1)]
    end

    def collect_whitespace(tokens, chars, indent_level)
      whitespace = capture_spaces(chars)
      if !whitespace.empty?
        tokens << make_apply_token(whitespace)
        chars = chars.drop(whitespace.size)
      end
      [tokens, chars, indent_level]
    end

    def make_apply_token(whitespace)
      [:APPLY, whitespace.size]
    end

    def collect_string(tokens, chars, indent_level)
      collect_string_delimiter(*collect_string_body(*collect_string_delimiter(tokens, chars, indent_level)))
    end

    def collect_string_body(tokens, chars, indent_level)
      match = chars.take_while{|i| i != STRING_LIM}.reduce("",:<<)
      [tokens << [:STRING, match], chars.drop(match.size), indent_level]
    end

    def collect_string_delimiter(tokens, chars, indent_level)
      if chars[0] = STRING_LIM
        rest = chars.drop(STRING_LIM.size)
        tokens << [:STRING_LIM]
      else
        rest = chars
      end
      [tokens, rest, indent_level]
    end

    def collect_number(tokens, chars, indent_level)
      match = ""
      while NUMERALS.include? chars[0]
        match, chars = collect_token_character(match, chars)
      end
      [tokens << [:NUMBER, match], chars, indent_level]
    end

    def collect_special_characters(tokens, chars, indent_level)
      if chars[0] == "\t"
        [tokens << [:TAB, Option::Lexer::EMPTY], chars.drop(1), indent_level]
      end
    end

    def drop_return(tokens, chars, indent_level)
      if chars[0] == "\r" then chars = chars.drop(1) end
      collect_end_of_program(tokens, chars, indent_level)
    end

    def collect_end_of_program(tokens, chars, indent_level)
      actual = chars.take(EOP.size).collect{|i| i}.reduce("", :<<)
      if actual == EOP
        tokens << [:EOP]
        chars = chars.drop(EOP.size)
        indent_level = INDENT_INVARIANT
      end
      [tokens, chars, indent_level]
    end

    def collect_indentation(tokens, chars, indent_level)
      if chars[0] == NEWLINE then chars = chars.drop(1) end
      following_whitespace = capture_spaces(chars)
      if indent?(following_whitespace, indent_level)
        indent_level = indent_size(following_whitespace, indent_level)
        tokens << [:INDENT, indent_level]
      elsif outdent?(following_whitespace, indent_level)
        indent_level = outdent_size(following_whitespace, indent_level)
        tokens << [:OUTDENT, indent_level]
      elsif aligned?(following_whitespace, indent_level)
        tokens << make_newline_token(following_whitespace)
      end
        [tokens, chars.drop(following_whitespace.size), indent_level]
    end

    def make_newline_token(whitespace)
      [:NEWLINE, whitespace.size]
    end

    def capture_spaces(chars)
      space = chars.take_while{|i| i == WHITESPACE}.collect{" "}.reduce(:<<)
      space.nil? ? "" : space
    end

    def indent?(whitespace_string, indent_count)
      if whitespace?(whitespace_string)
        spaces = whitespace_string.size
        lower = 2 * (indent_count + 1)
        (spaces >= lower) && (spaces <= lower + 1) ? true : false
      else
        false
      end
    end

    def indent_size(whitespace_string, indent_count)
      if indent?(whitespace_string, indent_count)
        indent_count + 1
      else
        raise TokenTypeError,
          "Space of size #{whitespace_string.size} is not an indent for "\
          "indent level #{indent_count}."
      end
    end

    def whitespace?(string)
      string.empty? || string.chars.all?{|i| i = " "}
    end

    def outdent?(whitespace_string, indent_count)
      if whitespace?(whitespace_string) && whitespace_string.size.even?
          (0...indent_count).cover?(whitespace_string.size / 2) ? true : false
      else
        false
      end
    end

    def outdent_size(whitespace_string, indent_count)
      if outdent?(whitespace_string, indent_count)
        whitespace_string.size / 2
      else
        raise TokenTypeError,
          "Space of size #{whitespace_string.size} is not an outdent for "\
          "indent level #{indent_count}."
      end
    end

    def aligned?(whitespace_string, indent_count)
      if whitespace? whitespace_string
        space = whitespace_string.size
        lower = 2 * indent_count
        space >= lower ? true : false
      else
        false
      end
    end

    def collect_delimiters(tokens, chars, indent_level)
      if chars[0] == COMMA
        whitespace = capture_spaces(chars.drop(1))
        tokens << make_comma_token(whitespace)
        chars = chars.drop(1 + whitespace.size)
      end
      [tokens, chars, indent_level]
    end

    def make_comma_token(whitespace)
      [:COMMA, whitespace.size]
    end
  end
end
