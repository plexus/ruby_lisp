(defmacro def (name val)
  (list 'define (list 'quote name) val))

(defmacro defun (name args body)
  (list 'def name (list 'lambda args body)))

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
  (reverse
   (reduce (lambda (c e)
             (cons (fn e) c))
           nil
           coll)))

(defmacro let (pairs body)
  (cons (cons 'lambda
              (cons (map car pairs)
                    (cons body nil)))
        (map car (map cdr pairs))))

(defun println (expr)
  (rb-send (rb-const 'Kernel) 'puts expr))

(defun concat (l1 l2)
  (if (nil? l1)
      l2
    (cons (car l1) (concat (cdr l1) l2))))

(defmacro defdelegate0 (name)
  (list 'defun name '(o)
        (list 'rb-send 'o (list 'quote name))))

(defun rb-send-const (const method args)
  (apply rb-send (cons (rb-const const) (cons method args))))

(defun rb-new (class args)
  (rb-send* class 'new args))

(defun require (file)
  (rb-send-const 'Kernel 'require (list file)))
