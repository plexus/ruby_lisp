module RubyLisp
  Cons = Struct.new(:car, :cdr) do
    def inspect
      if cdr.nil?
        "(#{car.inspect})"
      elsif cdr.is_a? Cons
        c = cdr
        s = "(#{car.inspect}"
        while c.is_a? Cons
          s << " #{c.car.inspect}"
          c = c.cdr
        end
        s << " #{c.inspect}" unless c.nil?
        s << ")"
      else
        "(#{car.inspect} . #{cdr.inspect})"
      end
    end

    def each(&block)
      return to_enum unless block_given?
      yield car
      return if cdr.nil?

      if cdr.is_a? Cons
        cdr.each(&block)
      else
        yield cdr
      end
    end

    def to_a
      each.to_a
    end
  end
end

# Can go away once we implement an actual writer instead of relying on
# inspect
class Symbol
  def inspect
    to_s
  end
end
