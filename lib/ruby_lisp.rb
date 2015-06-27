require 'stringio'

require 'ruby_lisp/read'
require 'ruby_lisp/cons'

class Symbol
  def inspect
    to_s
  end
end

class Environment < Hash
  def import(m)
    m.public_methods(false).each do |n|
      self[n] = m.method(n)
    end
    self
  end
end

Lambda = Struct.new(:env, :arg_names, :body) do
  def call(*args)
    RubyLisp::Core.new(env.merge(arg_names.zip(args).to_h)).eval(body)
  end
end

module RubyLisp

  class Core
    include Read
    def initialize(env = Environment.new.import(self))
      @env = env
    end

    def apply(callable, *args)
      callable.call(*args)
    end

    def eval(sexp)
      case sexp
      when String
        sexp
      when Numeric
        sexp
      when Symbol
        @env[sexp]
      when Cons
        car, cdr = sexp.car, sexp.cdr
        case car
        when :quote
          cdr.car
        when :def
          @env[cdr.car] = eval(cdr.cdr.car)
        when :lambda
          car, cdr = sexp.car, sexp.cdr
          arg_names = cdr.car
          body = cdr.cdr.car
          Lambda.new(@env, arg_names, body)
        else
          args = sexp.each.map(&method(:eval))
          apply(*args)
        end
      end
    end

    def car(cons)
      cons.car
    end

    def cdr(cons)
      cons.cdr
    end

    def cons(a, b)
      Cons.new(a, b)
    end

    def list(*args)
      if args.empty?
        nil
      else
        cons(args.first, list(*args.drop(1)))
      end
    end

    def +(*args)
      args.inject(:+)
    end
  end
end


__END__
$l=RubyLisp::Core.new

def exec(s)
  $l.eval($l.read(StringIO.new(s)))
end

exec "(def foo (lambda (a b) (+ a b)))"
exec "(foo 3 4)" # => 7
