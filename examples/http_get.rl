(require "net/http")

(defun uri (u)
  (rb-send* 'Kernel 'URI (list u)))

(defun http-get (u)
  (rb-send* 'Net::HTTP 'get_response (list (uri u))))

(let ((response (http-get "http://devblog.arnebrasseur.net")))
  (println (rb-send response 'body)))
