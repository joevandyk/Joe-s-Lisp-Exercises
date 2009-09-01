;;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; indent-tabs-mode: nil -*-
;;;
;;; --- Package definition.
;;;

(in-package :common-lisp-user)

(defpackage :io.multiplex
  (:nicknames #:iomux)
  (:use :iolib.base :cffi)
  (:export
   ;; Classes
   #:event-base
   #:multiplexer
   #:select-multiplexer
   #:poll-multiplexer
   #+bsd #:kqueue-multiplexer
   #+linux #:epoll-multiplexer

   ;; Event-base Operations
   #:*available-multiplexers*
   #:*default-multiplexer*
   #:*default-event-loop-timeout*
   #:add-timer
   #:event-base-empty-p
   #:event-dispatch
   #:exit-event-loop
   #:remove-timer
   #:remove-fd-handlers
   #:set-error-handler
   #:set-io-handler
   #:with-event-base

   ;; Operations on FDs
   #:fd-readablep
   #:fd-ready-p
   #:fd-writablep
   #:poll-error
   #:poll-error-fd
   #:poll-error-identifier
   #:wait-until-fd-ready
   #:poll-timeout
   #:poll-timeout-fd
   #:poll-timeout-event-type
   ))
