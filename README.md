# RubyLisp

A LISP in pure Ruby

* Lisp-1
* Dynamically scoped (closures)
* Macros
* Interop
* REPL
* Use lambdas as Ruby blocks
* Variable argument functions

Run `bin/ruby_lisp` to get a REPL, or pass it a filename to execute the file

Example:

``` lisp
(rb-require "net/http")

(defun uri (u)
  (rb-send-const 'Kernel 'URI u))

(defun http-get (u)
  (rb-send-const 'Net::HTTP 'get_response (uri u)))

(let ((response (http-get "http://devblog.arnebrasseur.net")))
  (println (rb-send response 'body)))
```

There are two interop primitives, `rb-const` and `rb-send`, for example println is implemented as

``` lisp
(defun println (expr)
  (rb-send (rb-const 'Kernel) 'puts expr))
```

Have a look at [bootstrap.rl](https://github.com/plexus/ruby_lisp/blob/master/lib/bootstrap.rl) for convenience functions built on top of these two, like `require`, `rb-new` and `rb-send-const`.

This is a minimal implementation, mostly intended for education. It complements my talk [Growing a LISP](http://devblog.arnebrasseur.net/speaking.html#rugb-lisp).

## Missing features

Lots, obviously, but the ones that would be most useful to have:

* comments
* backquotes

## License

[GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.en.html)
