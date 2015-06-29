module RubyLisp
  UnterminatedInput = Class.new(StandardError)

  module Read
    SYM_REGEXP = /[a-zA-Z0-9:\/\*!\?_+=\[\]-]/

    def read(io)
      skip_whitespace(io)
      return if io.eof?

      case peek(io)
      when '('
        read_list(io)
      when '0'..'9'
        read_number(io)
      when SYM_REGEXP
        read_symbol(io)
      when '"'
        read_string(io)
      when "'"
        assert_pop io,  "'"
        Cons.new(:quote, Cons.new(read(io), nil))
      end
    end

    private

    def assert_pop(io, char)
      popped = io.getc
      raise "Expected #{char}, got #{popped}" unless char == popped
    end

    def read_string(io)
      str = ""
      assert_pop io, '"'
      loop do
        char = io.getc
        case char
        when '\\'
          str << io.getc
        when ?"
          return str
        else
          str << char
        end
      end
    end

    def read_symbol(io)
      sym = ""
      loop do
        char = io.getc
        if char =~ SYM_REGEXP
          sym << char
        else
          io.ungetc(char)
          if sym == "nil"
            return nil
          else
            return sym.to_sym
          end
        end
      end
    end

    def read_number(io)
      num = ""
      loop do
        char = io.getc
        if char =~ /[0-9\.]/
          num << char
        else
          io.ungetc(char)
          return num.include?('.') ? num.to_f : num.to_i
        end
      end
    end

    def read_list(io)
      assert_pop io, '('
      skip_whitespace(io)

      char = peek(io)
      if char == ')'
        # empty list '()
        assert_pop io, ')'
        return
      end

      car = read(io)
      char = io.getc
      case char
      when nil
        raise UnterminatedInput
      when ')'
        return Cons.new(car, nil)
      end

      io.ungetc('(')
      cdr = read(io)
      Cons.new(car, cdr)
    end

    def skip_whitespace(io)
      char = io.getc
      while [" ", "\n", "\t"].include?(char)
        char = io.getc
      end
      io.ungetc(char) if char
    end

    def peek(io)
      io.getc.tap do |c|
        io.ungetc(c)
      end
    end

  end
end
