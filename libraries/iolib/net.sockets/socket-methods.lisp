;;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; indent-tabs-mode: nil -*-
;;;
;;; --- Various socket methods.
;;;

(in-package :net.sockets)

;;;-------------------------------------------------------------------------
;;; Shared Initialization
;;;-------------------------------------------------------------------------

(defun translate-make-socket-keywords-to-constants (address-family type protocol)
  (let ((sf (ecase address-family
              (:ipv4  af-inet)
              (:ipv6  af-inet6)
              (:local af-local)))
        (st (ecase type
              (:stream   sock-stream)
              (:datagram sock-dgram)))
        (sp (cond
              ((integerp protocol) protocol)
              ((eq :default protocol) 0)
              (t (lookup-protocol protocol)))))
    (values sf st sp)))

(defmethod socket-os-fd ((socket socket))
  (fd-of socket))

(defmethod initialize-instance :after ((socket socket) &key
                                       file-descriptor address-family type
                                       (protocol :default))
  (with-accessors ((fd fd-of) (fam socket-address-family) (proto socket-protocol))
      socket
    (setf fd (or file-descriptor
                 (multiple-value-call #'%socket
                   (translate-make-socket-keywords-to-constants
                    address-family type protocol))))
    (setf fam address-family
          proto protocol)))

(defun socket-read-fn (fd buffer nbytes)
  (debug-only
    (assert buffer)
    (assert fd))
  (%recvfrom fd buffer nbytes 0 (null-pointer) (null-pointer)))

(defun socket-write-fn (fd buffer nbytes)
  (debug-only
    (assert buffer)
    (assert fd))
  (%sendto fd buffer nbytes 0 (null-pointer) 0))

(defmethod (setf external-format-of) (external-format (socket passive-socket))
  (setf (slot-value socket 'external-format)
        (babel:ensure-external-format external-format)))

(defmethod initialize-instance :after ((socket passive-socket) &key external-format
                                       input-buffer-size output-buffer-size)
  ;; Makes CREATE-SOCKET simpler
  (declare (ignore input-buffer-size output-buffer-size))
  (setf (external-format-of socket) external-format))


;;;-------------------------------------------------------------------------
;;; Misc
;;;-------------------------------------------------------------------------

(defmethod socket-type ((socket stream-socket))
  :stream)

(defmethod socket-type ((socket datagram-socket))
  :datagram)

(defun ipv6-socket-p (socket)
  "Return T if SOCKET is an AF_INET6 socket."
  (eq :ipv6 (socket-address-family socket)))


;;;-------------------------------------------------------------------------
;;; PRINT-OBJECT
;;;-------------------------------------------------------------------------

(defun sock-fam (socket)
  (ecase (socket-address-family socket)
    (:ipv4 "IPv4")
    (:ipv6 "IPv6")))

(defmethod print-object ((socket socket-stream-internet-active) stream)
  (print-unreadable-object (socket stream :identity t)
    (format stream "active ~A stream socket" (sock-fam socket))
    (if (socket-connected-p socket)
        (multiple-value-bind (host port) (remote-name socket)
          (format stream " connected to ~A/~A"
                  (address-to-string host) port))
        (format stream ", ~:[closed~;unconnected~]" (fd-of socket)))))

(defmethod print-object ((socket socket-stream-internet-passive) stream)
  (print-unreadable-object (socket stream :identity t)
    (format stream "passive ~A stream socket" (sock-fam socket))
    (if (socket-bound-p socket)
        (multiple-value-bind (host port) (local-name socket)
          (format stream " ~:[bound to~;waiting @~] ~A/~A"
                  (socket-listening-p socket)
                  (address-to-string host) port))
        (format stream ", ~:[closed~;unbound~]" (fd-of socket)))))

(defmethod print-object ((socket socket-stream-local-active) stream)
  (print-unreadable-object (socket stream :identity t)
    (format stream "active local stream socket")
    (if (socket-connected-p socket)
        (format stream " connected to ~S"
                (address-to-string (remote-filename socket)))
        (format stream ", ~:[closed~;unconnected~]" (fd-of socket)))))

(defmethod print-object ((socket socket-stream-local-passive) stream)
  (print-unreadable-object (socket stream :identity t)
    (format stream "passive local stream socket")
    (if (socket-bound-p socket)
        (format stream " ~:[bound to~;waiting @~] ~S"
                  (socket-listening-p socket)
                  (address-to-string (local-filename socket)))
        (format stream ", ~:[closed~;unbound~]" (fd-of socket)))))

(defmethod print-object ((socket socket-datagram-local-active) stream)
  (print-unreadable-object (socket stream :identity t)
    (format stream "local datagram socket")
    (if (socket-connected-p socket)
        (format stream " connected to ~S"
                (address-to-string (remote-filename socket)))
        (if (fd-of socket)
            (format stream " waiting @ ~S" (address-to-string (local-filename socket)))
            (format stream ", closed" )))))

(defmethod print-object ((socket socket-datagram-internet-active) stream)
  (print-unreadable-object (socket stream :identity t)
    (format stream "~A datagram socket" (sock-fam socket))
    (if (socket-connected-p socket)
        (multiple-value-bind (host port) (remote-name socket)
          (format stream " connected to ~A/~A"
                  (address-to-string host) port))
        (if (fd-of socket)
            (multiple-value-bind (host port) (local-name socket)
              (format stream " waiting @ ~A/~A"
                      (address-to-string host) port))
            (format stream ", closed" )))))


;;;-------------------------------------------------------------------------
;;; CLOSE
;;;-------------------------------------------------------------------------

(defmethod close :around ((socket socket) &key abort)
  (declare (ignore abort))
  (call-next-method)
  (setf (slot-value socket 'bound) nil)
  (values socket))

(defmethod close :around ((socket passive-socket) &key abort)
  (declare (ignore abort))
  (call-next-method)
  (setf (slot-value socket 'listening) nil)
  (values socket))

(defmethod close ((socket socket) &key abort)
  (declare (ignore socket abort)))

(defmethod socket-open-p ((socket socket))
  (when (fd-of socket)
    (with-sockaddr-storage-and-socklen (ss size)
      (handler-case
          (%getsockname (fd-of socket) ss size)
        (isys:ebadf () nil)
        (socket-connection-reset-error () nil)
        (:no-error (_) (declare (ignore _)) t)))))


;;;-------------------------------------------------------------------------
;;; GETSOCKNAME
;;;-------------------------------------------------------------------------

(defun %local-name (socket)
  (with-sockaddr-storage-and-socklen (ss size)
    (%getsockname (fd-of socket) ss size)
    (sockaddr-storage->sockaddr ss)))

(defmethod local-name ((socket socket))
  (%local-name socket))

(defmethod local-host ((socket internet-socket))
  (nth-value 0 (%local-name socket)))

(defmethod local-port ((socket internet-socket))
  (nth-value 1 (%local-name socket)))

(defmethod local-filename ((socket local-socket))
  (%local-name socket))


;;;-------------------------------------------------------------------------
;;; GETPEERNAME
;;;-------------------------------------------------------------------------

(defun %remote-name (socket)
  (with-sockaddr-storage-and-socklen (ss size)
    (%getpeername (fd-of socket) ss size)
    (sockaddr-storage->sockaddr ss)))

(defmethod remote-name ((socket socket))
  (%remote-name socket))

(defmethod remote-host ((socket internet-socket))
  (nth-value 0 (%remote-name socket)))

(defmethod remote-port ((socket internet-socket))
  (nth-value 1 (%remote-name socket)))

(defmethod remote-filename ((socket local-socket))
  (%remote-name socket))


;;;-------------------------------------------------------------------------
;;; BIND
;;;-------------------------------------------------------------------------

(defmethod bind-address :before ((socket internet-socket) address
                                 &key (reuse-address t))
  (declare (ignore address))
  (when reuse-address
    (setf (socket-option socket :reuse-address) t)))

(defun bind-ipv4-address (fd address port)
  (with-sockaddr-in (sin address port)
    (%bind fd sin size-of-sockaddr-in)))

(defun bind-ipv6-address (fd address port)
  (with-sockaddr-in6 (sin6 address port)
    (%bind fd sin6 size-of-sockaddr-in6)))

(defmethod bind-address ((socket internet-socket) (address ipv4-address)
                         &key (port 0))
  (let ((port (ensure-numerical-service port)))
    (if (ipv6-socket-p socket)
        (bind-ipv6-address (fd-of socket)
                           (map-ipv4-vector-to-ipv6 (address-name address))
                           port)
        (bind-ipv4-address (fd-of socket) (address-name address) port)))
  (values socket))

(defmethod bind-address ((socket internet-socket) (address ipv6-address)
                         &key (port 0))
  (bind-ipv6-address (fd-of socket)
                     (address-name address)
                     (ensure-numerical-service port))
  (values socket))

(defmethod bind-address ((socket local-socket) (address local-address) &key)
  (with-sockaddr-un (sun (address-name address))
    (%bind (fd-of socket) sun size-of-sockaddr-un))
  (values socket))

(defmethod bind-address :after ((socket socket) (address address) &key)
  (setf (slot-value socket 'bound) t))


;;;-------------------------------------------------------------------------
;;; LISTEN
;;;-------------------------------------------------------------------------

(defmethod listen-on ((socket passive-socket) &key backlog)
  (unless backlog (setf backlog (min *default-backlog-size*
                                     +max-backlog-size+)))
  (check-type backlog unsigned-byte "a non-negative integer")
  (%listen (fd-of socket) backlog)
  (setf (slot-value socket 'listening) t)
  (values socket))

(defmethod listen-on ((socket active-socket) &key)
  (error "You can't listen on active sockets."))


;;;-------------------------------------------------------------------------
;;; ACCEPT
;;;-------------------------------------------------------------------------

(defmethod accept-connection ((socket active-socket) &key)
  (error "You can't accept connections on active sockets."))

(defmethod accept-connection ((socket passive-socket) &key external-format
                              input-buffer-size output-buffer-size
                              (wait t) (timeout nil))
  (flet ((make-client-socket (fd)
           (make-instance (active-class socket)
                          :address-family (socket-address-family socket)
                          :file-descriptor fd
                          :external-format (or external-format
                                               (external-format-of socket))
                          :input-buffer-size input-buffer-size
                          :output-buffer-size output-buffer-size)))
    (ignore-some-conditions (iomux:poll-timeout)
      (when wait (iomux:wait-until-fd-ready (fd-of socket) :input timeout t))
      (with-sockaddr-storage-and-socklen (ss size)
        (ignore-some-conditions (isys:ewouldblock)
          (make-client-socket (%accept (fd-of socket) ss size)))))))


;;;-------------------------------------------------------------------------
;;; CONNECT
;;;-------------------------------------------------------------------------

(defun ipv4-connect (fd address port)
  (with-sockaddr-in (sin address port)
    (%connect fd sin size-of-sockaddr-in)))

(defun ipv6-connect (fd address port)
  (with-sockaddr-in6 (sin6 address port)
    (%connect fd sin6 size-of-sockaddr-in6)))

(defun call-with-socket-to-wait-connect (socket thunk wait timeout)
  (flet
      ((wait-connect (err)
         (cond
           (wait
            (iomux:wait-until-fd-ready (fd-of socket) :output timeout t)
            (let ((errcode (socket-option socket :error)))
              (unless (zerop errcode)
                (signal-socket-error errcode (fd-of socket)))))
           (t (error err)))))
    (handler-case
        (funcall thunk)
      (isys:ewouldblock (err) (wait-connect err))
      (isys:einprogress (err) (wait-connect err)))))

(defmacro with-socket-to-wait-connect ((socket wait timeout) &body body)
  `(call-with-socket-to-wait-connect ,socket (lambda () ,@body) ,wait ,timeout))

(defmethod connect ((socket internet-socket) (address inet-address)
                    &key (port 0) (wait t) (timeout nil))
  (let ((name (address-name address))
        (port (ensure-numerical-service port)))
    (with-socket-to-wait-connect (socket wait timeout)
      (cond
        ((ipv6-socket-p socket)
         (when (ipv4-address-p address)
           (setf name (map-ipv4-vector-to-ipv6 name)))
         (ipv6-connect (fd-of socket) name port))
        (t (ipv4-connect (fd-of socket) name port)))))
  (values socket))

(defmethod connect ((socket local-socket) (address local-address) &key)
  (with-sockaddr-un (sun (address-name address))
    (%connect (fd-of socket) sun size-of-sockaddr-un))
  (values socket))

(defmethod connect ((socket passive-socket) address &key)
  (declare (ignore address))
  (error "You cannot connect passive sockets."))

(defmethod socket-connected-p ((socket socket))
  (when (fd-of socket)
    (with-sockaddr-storage-and-socklen (ss size)
      (handler-case
          (%getpeername (fd-of socket) ss size)
        (socket-not-connected-error () nil)
        (:no-error (_) (declare (ignore _)) t)))))


;;;-------------------------------------------------------------------------
;;; DISCONNECT
;;;-------------------------------------------------------------------------

(defmethod disconnect :before ((socket socket))
  (unless (typep socket 'datagram-socket)
    (error "You can only disconnect active datagram sockets.")))

(defmethod disconnect ((socket datagram-socket))
  (with-foreign-object (sin 'sockaddr-in)
    (isys:%sys-bzero sin size-of-sockaddr-in)
    (setf (foreign-slot-value sin 'sockaddr-in 'addr) af-unspec)
    (%connect (fd-of socket) sin size-of-sockaddr-in)
    (values socket)))


;;;-------------------------------------------------------------------------
;;; SHUTDOWN
;;;-------------------------------------------------------------------------

(defmethod shutdown ((socket socket) &key read write)
  (assert (or read write) (read write)
          "You must select at least one direction to shut down.")
  (%shutdown (fd-of socket)
             (multiple-value-case ((read write))
               ((*   nil) shut-rd)
               ((nil *)   shut-wr)
               (t         shut-rdwr)))
  (values socket))


;;;-------------------------------------------------------------------------
;;; Socket flag definition
;;;-------------------------------------------------------------------------

(defmacro define-socket-flag (place name value platform)
  (let ((val (cond ((or (not platform)
                        (featurep platform)) value)
                   ((not (featurep platform)) 0))))
    `(pushnew (cons ,name ,val) ,place)))

(defmacro define-socket-flags (place &body definitions)
  (flet ((dflag (form)
           (destructuring-bind (name value &optional platform) form
             `(define-socket-flag ,place ,name ,value ,platform))))
    `(progn
       ,@(mapcar #'dflag definitions))))


;;;-------------------------------------------------------------------------
;;; SENDTO
;;;-------------------------------------------------------------------------

(defvar *sendto-flags* ())

(define-socket-flags *sendto-flags*
  (:dont-route    msg-dontroute)
  (:dont-wait     msg-dontwait  (:not :windows))
  (:out-of-band   msg-oob)
  (:more          msg-more      :linux)
  (:confirm       msg-confirm   :linux))

(defun %%send-to (fd ss got-peer buffer start length flags)
  (with-pointer-to-vector-data (buff-sap buffer)
    (incf-pointer buff-sap start)
    (loop
       (restart-case
           (return*
            (%sendto fd buff-sap length flags
                     (if got-peer ss (null-pointer))
                     (if got-peer (sockaddr-size ss) 0)))
         (ignore ()
           :report "Ignore this socket condition"
           (return* 0))
         (retry (&optional (timeout 15.0d0))
           :report "Try to send data again"
           (when (plusp timeout)
             (iomux:wait-until-fd-ready fd :output timeout nil)))))))

(defun %send-to (fd ss got-peer buffer start end flags)
  (check-bounds buffer start end)
  (etypecase buffer
    (ub8-sarray
     (%%send-to fd ss got-peer buffer start (- end start) flags))
    ((or ub8-vector (vector t))
     (%%send-to fd ss got-peer (coerce buffer 'ub8-sarray)
                start (- end start) flags))))

(defmethod send-to ((socket internet-socket) buffer &rest args
                    &key (start 0) end remote-host (remote-port 0) flags (ipv6 *ipv6*))
  (let ((*ipv6* ipv6))
    (with-sockaddr-storage (ss)
      (when remote-host
        (sockaddr->sockaddr-storage ss (ensure-hostname remote-host)
                                    (ensure-numerical-service remote-port)))
      (%send-to (fd-of socket) ss (if remote-host t) buffer start end
                (or flags (compute-flags *sendto-flags* args))))))

(defmethod send-to ((socket local-socket) buffer &rest args
                    &key (start 0) end remote-filename flags)
  (with-sockaddr-storage (ss)
    (when remote-filename
      (sockaddr->sockaddr-storage ss (ensure-address remote-filename :family :local) 0))
    (%send-to (fd-of socket) ss (if remote-filename t) buffer start end
              (or flags (compute-flags *sendto-flags* args)))))

(define-compiler-macro send-to (&whole form socket buffer &rest args
                                &key (start 0) end (remote-host nil host-p) (remote-port 0 port-p)
                                (remote-filename nil file-p) flags (ipv6 '*ipv6* ipv6-p) &allow-other-keys)
  (let ((flags-val (compute-flags *sendto-flags* args)))
    (cond
      ((and (not flags) flags-val)
       (append
        `(send-to ,socket ,buffer :start ,start :end ,end :flags ,flags-val)
        (when host-p `(:remote-host ,remote-host))
        (when port-p `(:remote-port ,remote-port))
        (when ipv6-p `(:ipv6 ,ipv6))
        (when file-p `(:remote-filename ,remote-filename))))
      (t
       form))))


;;;-------------------------------------------------------------------------
;;; RECVFROM
;;;-------------------------------------------------------------------------

(defvar *recvfrom-flags* ())

(define-socket-flags *recvfrom-flags*
  (:out-of-band msg-oob)
  (:peek        msg-peek)
  (:wait-all    msg-waitall  (:not :windows))
  (:dont-wait   msg-dontwait (:not :windows)))

(defun %%receive-from (fd ss size buffer start length flags)
  (with-pointer-to-vector-data (buff-sap buffer)
    (incf-pointer buff-sap start)
    (loop
       (restart-case
           (return* (%recvfrom fd buff-sap length flags ss size))
         (ignore ()
           :report "Ignore this socket condition"
           (return* 0))
         (retry (&optional (timeout 15.0d0))
           :report "Try to receive data again"
           (when (plusp timeout)
             (iomux:wait-until-fd-ready fd :input timeout nil)))))))

(defun %receive-from (fd ss size buffer start end flags)
  (check-bounds buffer start end)
  (flet ((%do-recvfrom (buff start length)
           (%%receive-from fd ss size buff start length flags)))
    (let (nbytes)
      (etypecase buffer
        (ub8-sarray
         (setf nbytes (%do-recvfrom buffer start (- end start))))
        ((or ub8-vector (vector t))
         (let ((tmpbuff (make-array (- end start) :element-type 'ub8)))
           (setf nbytes (%do-recvfrom tmpbuff 0 (- end start)))
           (replace buffer tmpbuff :start1 start :end1 end :start2 0 :end2 nbytes))))
      (values nbytes))))

(defmethod receive-from :around ((socket active-socket) &rest args
                                 &key buffer size (start 0) end flags &allow-other-keys)
  (let ((flags-val (or flags (compute-flags *recvfrom-flags* args))))
    (cond
      (buffer
       (call-next-method socket :buffer buffer :start start :end end :flags flags-val))
      (t
       (check-type size unsigned-byte "a non-negative integer")
       (call-next-method socket :buffer (make-array size :element-type 'ub8)
                         :start 0 :end size :flags flags-val)))))

(defmethod receive-from ((socket stream-socket) &key buffer start end flags)
  (with-sockaddr-storage-and-socklen (ss size)
    (let ((nbytes (%receive-from (fd-of socket) ss size buffer start end flags)))
      (values buffer nbytes))))

(defmethod receive-from ((socket datagram-socket) &key buffer start end flags)
  (with-sockaddr-storage-and-socklen (ss size)
    (let ((nbytes (%receive-from (fd-of socket) ss size buffer start end flags)))
      (multiple-value-call #'values buffer nbytes
                           (sockaddr-storage->sockaddr ss)))))

(define-compiler-macro receive-from (&whole form socket &rest args
                                     &key buffer size (start 0) end flags &allow-other-keys)
  (let ((flags-val (compute-flags *recvfrom-flags* args)))
    (cond
      ((and (not flags) flags-val)
       `(receive-from ,socket :buffer ,buffer :start ,start :end ,end
                      :size ,size :flags ,flags-val))
      (t
       form))))
