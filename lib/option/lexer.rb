module Lexer

  TokenTypeError = Class.new(StandardError)
  InvariantError = Class.new(StandardError)

  EMPTY = ""
  WHITESPACE = " "
  COMMA = ","
  RETURN = "\r"
  NEWLINE = "\n"
  TAB = "\t"
  STRING_LIM = '"'
  NUMERALS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
  EOP = "..EOP"
  SPECIAL_CHARACTERS =[RETURN, NEWLINE, TAB]
  DELIMITERS = [COMMA]
  ENDWORD = SPECIAL_CHARACTERS + [WHITESPACE]
  INDENT_INVARIANT = 0

  extend self

  def tokenize(source)
    tokens = []
    source = String.new(source)
    unless source.empty?
      scan_result = scan [tokens, trim_program(source), INDENT_INVARIANT]
    end
    if(indent_level(scan_result) !=INDENT_INVARIANT || !chars(scan_result).empty?)
      raise InvariantError,
        "You should never see this message. If you are, it means that "\
        "Lexical Analysis has failed for your program. Please report this "\
        "error to maintainer(s)."
    end
    return tokens(scan_result)
  end

  def trim_program(source)
    trimmed = source.chomp!
    trimmed.empty? ? trimmed.chars : trimmed.concat("\r").concat(EOP).chars
  end

  def tokens(acc_array) acc_array[0] end

  def chars(acc_array) acc_array[1] end

  def indent_level(acc_array) acc_array[2] end

  def scan(acc_array)
    if chars(acc_array).empty?
      acc_array
    else
      chead = chars(acc_array)[0]
      tokens = tokens(acc_array)
      chars = chars(acc_array)
      indent_level = indent_level(acc_array)
      if chead == WHITESPACE
        scan(collect_whitespace(tokens, chars, indent_level))
      elsif DELIMITERS.include? chead
        scan(collect_delimiters(tokens, chars, indent_level))
      elsif chead == STRING_LIM
        scan(collect_string(acc_array))
      elsif NUMERALS.include? chead
        scan(collect_number(tokens, chars, indent_level))
      elsif chead == RETURN
        scan(drop_return(tokens, chars, indent_level))
      elsif chead == NEWLINE
        scan(collect_indentation(tokens, chars, indent_level))
      elsif SPECIAL_CHARACTERS.include? chead
        scan(collect_special_characters(tokens, chars, indent_level))
      else
        scan(collect_symbol(tokens, chars, indent_level))
      end
    end
  end

  def collect_symbol(tokens, chars, indent_level)
    sym = chars.take_while{|i| !ENDWORD.include?i}.reduce("", :<<)
    [tokens << [:SYMBOL, sym], chars.drop(sym.size), indent_level]
  end

  def collect_whitespace(tokens, chars, indent_level)
    whitespace = capture_spaces(chars)
    tokens << make_apply_token(whitespace) if !whitespace.empty?
    [tokens, chars.drop(whitespace.size), indent_level]
  end

  def make_apply_token(whitespace)
    [:APPLY, whitespace.size]
  end

  def collect_string(acc_array)
    collect_string_delimiter(
      collect_string_body(collect_string_delimiter(acc_array)))
  end

  def collect_string_body(acc_array)
    match = chars(acc_array).take_while{|i| i != STRING_LIM}.reduce("",:<<)
    [tokens(acc_array) << [:STRING, match],
    chars(acc_array).drop(match.size),
    indent_level(acc_array)]
  end

  def collect_string_delimiter(acc_array)
    if chars(acc_array)[0] = STRING_LIM
      [tokens(acc_array) << [:STRING_LIM],
      chars(acc_array).drop(STRING_LIM.size), indent_level(acc_array)]
    else
      [tokens(acc_array), chars(acc_array), indent_level(acc_array)]
    end
  end

  def collect_number(tokens, chars, indent_level)
    match = chars.take_while{|i| NUMERALS.include?i}.reduce("",:<<)
    [tokens << [:NUMBER, match], chars.drop(match.size), indent_level]
  end

  def collect_special_characters(tokens, chars, indent_level)
    tokens << [:TAB, Option::Lexer::EMPTY] if chars[0] == TAB
    [tokens, chars.drop(1), indent_level]
  end

  def drop_return(tokens, chars, indent_level)
    if chars[0] == RETURN
      collect_end_of_program(tokens, chars.drop(1), indent_level)
    else
      [tokens, chars, indent_level]
    end
  end

  def collect_end_of_program(tokens, chars, indent_level)
    actual = chars.take(EOP.size).collect{|i| i}.reduce("", :<<)
    if actual == EOP
      [tokens << [:EOP], chars.drop(EOP.size), INDENT_INVARIANT]
    else
      [tokens, chars, indent_level]
    end
  end

  def collect_indentation(tokens, chars, indent_level)
    chars = chars.drop(1) if chars[0] == NEWLINE
    whitespace = capture_spaces(chars)
    if indent?(whitespace, indent_level)
      indent = indent_size(whitespace, indent_level)
      tokens << [:INDENT, indent]
      [tokens, chars.drop(whitespace.size), indent]
    elsif outdent?(whitespace, indent_level)
      indent = outdent_size(whitespace, indent_level)
      tokens << [:OUTDENT, indent]
      [tokens, chars.drop(whitespace.size), indent]
    elsif aligned?(whitespace, indent_level)
      tokens << make_newline_token(whitespace)
      [tokens, chars.drop(whitespace.size), indent_level]
    end
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
      [tokens << make_comma_token(whitespace),
        chars.drop(1 + whitespace.size), indent_level]
    else
      [tokens, chars, indent_level]
    end
  end

  def make_comma_token(whitespace)
    [:COMMA, whitespace.size]
  end
end
