(defun assert-equal (a b)
  (if (not (== a b))
      (rb-send Kernel 'raise (string "Expected " b " got " a))
    (print ".")))

(assert-equal (rb-new 'String "foo") "foo")
