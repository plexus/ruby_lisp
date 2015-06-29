require_relative '../test_setup'

require 'ruby_lisp/read'
require 'ruby_lisp/cons'

module RubyLisp
  class ReadTest < MiniTest::Unit::TestCase
    def reader
      @reader ||= Class.new {include Read}.new
    end

    def assert_read(sexp, str)
      assert_equal sexp, reader.read(StringIO.new(str))
    end

    def test_read
      assert_read nil, "nil"
      assert_read nil, "()"
      assert_read :quote, "quote"
      assert_read 123.45, "123.45"
      assert_read Cons.new(:quote, Cons.new(:foo)), "'foo"
      assert_read Cons.new(1, nil), "(1)"
      assert_read Cons.new(1, Cons.new(2, Cons.new(3, nil))), "(1 2 3)"
      assert_read Cons.new(1, Cons.new(2, Cons.new(3, nil))), "  \n  (   1 \n\t 2 \n 3   )  "
    end
  end
end
