(require "net/http")

(defun uri (u)
  (rb-send-const 'Kernel 'URI (list u)))

(defun http-get (u)
  (rb-send-const 'Net::HTTP 'get_response (list (uri u))))

(let ((response (http-get "http://devblog.arnebrasseur.net")))
  (println (rb-send response 'body)))
