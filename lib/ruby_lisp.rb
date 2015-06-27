require 'stringio'

require 'ruby_lisp/read'
require 'ruby_lisp/cons'


Lambda = Struct.new(:env, :arg_names, :body) do
  def call(*args)
    env.merge(arg_names.zip(args).to_h).eval(body)
  end
end

module RubyLisp

  class Core
    include Read

    def initialize(binding = {})
      @binding = binding
      @macros = {}
    end

    def exec(string)
      eval(macroexpand(read(StringIO.new(string))))
    end

    def resolve(symbol)
      @binding.fetch(symbol) { public_method(symbol) }
    end

    def def(symbol, value)
      @binding[symbol] = value
    end

    def merge(bind)
      self.class.new(@binding.merge(bind))
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
          args = sexp.each.map(&method(:eval))
          apply(*args)
        end
      end
    end

    def macroexpand(sexp)
      return sexp unless cons? sexp
      first = sexp.car
      return sexp if first == :quote || first == :defmacro

      macro = @macros[first]
      if macro
        macroexpand(apply(macro, *sexp.cdr.each))
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

    define_method :"rb-const" do |name|
      name.to_s.split('::').inject(Kernel) {|ns, n| ns.const_get(n) }
    end
  end
end


if $0 == __FILE__
  require 'readline'
  require 'pathname'

  $l=RubyLisp::Core.new
  histfile = Pathname('~/.ruby-lisp-history').expand_path
  if histfile.exist?
    histfile.read.split("\n").each do |l|
      Readline::HISTORY.push l
    end
  end

  begin
    loop do
      code = Readline::readline '>> '
      Readline::HISTORY.push code
      begin
        puts $l.exec(code).inspect
      rescue => e
        puts e
        puts e.backtrace
      end
    end
  ensure
    histfile.write(Readline::HISTORY.to_a.join("\n"))
  end
end

__END__

(defmacro defn (name args body) (list 'def (list 'quote name) (list 'lambda args body)))

(defn last (l) (if (nil? (cdr l)) (car l) (last (cdr l))))

(defn reverse1 (l c) (if (nil? l) c (reverse1 (cdr l) (cons (car l) c))))
(defn reverse (l) (reverse1 l nil))

(defn map (fn coll) (reverse (reduce (lambda (c e) (cons (fn e) c)) nil coll)))

(defmacro let (pairs body) (cons (cons 'lambda (cons (map car pairs) body)) (map car (map cdr pairs))))
