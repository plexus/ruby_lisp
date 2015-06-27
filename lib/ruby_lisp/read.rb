module RubyLisp
  module Read
    SYM_REGEXP = /[a-zA-Z0-9:\/\*!\?_+=-]/

    def read(io)
      char = io.getc
      io.ungetc(char)
      case char
      when '('
        read_list(io)
      when '1'..'9'
        read_number(io)
      when SYM_REGEXP
        read_symbol(io)
      when '"'
        read_string(io)
      when "'"
        assert_pop io,  "'"
        list(:quote, read(io))
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
      car = read(io)
      char = io.getc
      case char
      when nil
        raise "List not terminated"
      when ')'
        return cons(car, nil)
      end

      io.ungetc('(')
      cdr = read(io)
      cons(car, cdr)
    end

  end
end
