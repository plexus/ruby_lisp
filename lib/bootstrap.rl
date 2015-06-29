(defmacro def (name val)
  (list 'define (list 'quote name) val))

(defmacro defun (name args body)
  (list 'def name (list 'lambda args body)))

(def Array (rb-const 'Array))
(def Kernel (rb-const 'Kernel))
(def false nil)
(def true 'true)

(defun last (l)
  (if (nil? (cdr l))
      (car l)
    (last (cdr l))))

(defun reverse1 (l c)
  (if (nil? l)
      c
    (reverse1 (cdr l) (cons (car l) c))))

(defun reverse (l)
  (reverse1 l nil))

(defun map (fn coll)
  (if (rb-send coll 'respond_to? 'map)
      (rb-send-block coll 'map fn)
    (reverse
     (reduce (lambda (c e)
               (cons (fn e) c))
             nil
             coll))))

(defmacro let (pairs body)
  (cons (cons 'lambda
              (cons (map car pairs)
                    (cons body nil)))
        (map car (map cdr pairs))))

(defun println (expr)
  (rb-send Kernel 'puts expr))

(defun print (expr)
  (rb-send Kernel 'print expr))

(defun p (expr)
  (rb-send Kernel 'p expr))

(defun concat (l1 l2)
  (if (nil? l1)
      l2
    (cons (car l1) (concat (cdr l1) l2))))

(defmacro def-delegate (name)
  (list 'defun name '(o *args)
        (list 'apply 'rb-send (cons 'o (cons (list 'quote name) args)))))

(defun rb-send-const (const method *args)
  (apply rb-send (cons (rb-const const) (cons method args))))

(defun rb-new (class *args)
  (apply (rb-send-const class 'public_method 'new) args))

(defun rb-method (o m)
  (rb-send o 'public_method m))

(defun require (file)
  (rb-send-const 'Kernel 'require file))

(defun array (*e)
  (apply (rb-method Array '[]) e))

(defun string (*s)
  (rb-send (apply array s) 'join))

(defun not (b)
  (if b
      false
    true))
