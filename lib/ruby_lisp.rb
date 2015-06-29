require 'stringio'

require 'ruby_lisp/read'
require 'ruby_lisp/cons'


module RubyLisp

  class StackException < StandardError
    attr_reader :callable, :args, :source

    def initialize(callable, args, source)
      @callable, @args, @source = callable, args, source
    end

    def to_s
      [
        [@callable.inspect, @args.inspect].join,
        source.is_a?(StackException) ? source : [source.message, source.backtrace].join("\n")
      ].join("\n")
    end
  end

  Lambda = Struct.new(:env, :arg_names, :body) do
    def call(*args)
      names     = arg_names.to_a
      arity     = names.length
      last_name = names.last.to_s

      if last_name.start_with?('*')
        # splat varargs
        new_binding = names.take(arity - 1).zip(args.take(arity - 1)).to_h
        new_binding[last_name[1..-1].to_sym] = env.list(*args.drop(arity - 1))
      else
        new_binding = names.zip(args).to_h
      end

      env.merge(new_binding).eval(body)
    end

    def to_proc
      public_method(:call).to_proc
    end

    def inspect
      Cons.new(:lambda, Cons.new(arg_names, Cons.new(body, nil))).inspect
    end
  end

  class Core
    include Read

    def initialize(binding = {})
      @binding = binding
      @macros = {}
    end

    def exec(io)
      if io.is_a? String
        io = StringIO.new(io)
      end
      ret = nil
      until io.eof?
        ret = eval(macroexpand(read(io)))
      end
      ret
    rescue StackException => e
      puts e
    end

    def resolve(symbol)
      @binding.fetch(symbol) { public_method(symbol) }
    end

    def define(symbol, value)
      @binding[symbol] = value
    end

    def merge(bind)
      self.class.new(@binding.merge(bind))
    end

    def apply(callable, args)
      callable.call(*args)
    rescue => ex
      raise StackException.new(callable, args, ex)
    end

    def eval(sexp)
      case sexp
      when String
        sexp
      when Numeric
        sexp
      when Symbol
        resolve(sexp)
      when Cons
        car, cdr = sexp.car, sexp.cdr
        case car
        when :quote
          cdr.car
        when :lambda
          arg_names = nth(sexp, 1)
          body = sexp.cdr.cdr
          Lambda.new(self, arg_names, cons(:do, body))
        when :defmacro
          name = nth(sexp, 1)
          arg_names = nth(sexp, 2)
          body = nth(sexp, 3)
          @macros[name] = Lambda.new(self, arg_names, body)
        when :if
          cond = nth(sexp, 1)
          pos = nth(sexp, 2)
          neg = nth(sexp, 3)
          if eval(cond)
            eval(pos)
          else
            eval(neg)
          end
        when :do
          r=nil
          sexp.cdr.each do |s|
            r=eval(s)
          end
          r
        else
          apply(eval(sexp.car), sexp.cdr.map(&method(:eval)))
        end
      end
    end

    def macroexpand(sexp)
      return sexp unless cons? sexp
      first = sexp.car
      return sexp if first == :quote || first == :defmacro

      macro = @macros[first]
      if macro
        macroexpand(apply(macro, sexp.cdr.each))
      else
        cons(sexp.car, macroexpand(sexp.cdr))
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

    def list?(sexp)
      nil?(sexp) || cons?(sexp)
    end

    def nil?(sexp)
      sexp.nil?
    end

    def cons?(sexp)
      sexp.is_a? Cons
    end

    %w[+ * - / == === eql? :equal?].each do |s|
      define_method(s) {|*args| args.inject(s) }
    end


    def nth(list, n)
      return if list.nil?
      if n == 0
        list.car
      else
        nth(list.cdr, n - 1)
      end
    end

    def reduce(fn, start, coll = :none)
      return start if coll.nil?
      start, coll = start.car, start.cdr if coll == :none
      reduce(fn, fn.call(start, coll.car), coll.cdr)
    end

    define_method :"rb-send" do |obj, method, *args|
      obj.public_send(method, *args)
    end

    define_method :"rb-send-block" do |obj, method, *args|
      block = args.last
      real_args = args.take(args.length - 1)
      obj.public_send(method, *real_args, &block)
    end

    define_method :"rb-const" do |name|
      name.to_s.split('::').inject(Kernel) {|ns, n| ns.const_get(n) }
    end
  end
end
