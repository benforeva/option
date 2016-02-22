module TestHelpers

  module TestPrograms
    extend self

    def get_test_program(file_name)
      file = File.expand_path("../../test/test_programs/#{file_name}", __FILE__)
      File.open(file).read
    end
  end

  module LexerHelper

    def make_space(no_of_spaces=0)
      return " "*no_of_spaces
    end

    def indent_error_message(whitespace, indent_count)
      "whitespace of length #{whitespace.size} is not an indentation for "\
      "indent level #{indent_count}"
    end

    def no_indent_error_message(whitespace, indent_count)
      "whitespace of length #{whitespace.size} is an indentation for "\
      "indent level #{indent_count}"
    end

    def outdent_error_message(whitespace, indent_count)
      "whitespace of length #{whitespace.size} is not an outdentation for "\
      "indent level #{indent_count}"
    end

    def no_outdent_error_message(whitespace, indent_count)
      "whitespace of length #{whitespace.size} is an outdentation for "\
      "indent level #{indent_count}"
    end
  end
end
