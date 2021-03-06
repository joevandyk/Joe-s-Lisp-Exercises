;;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; indent-tabs-mode: nil -*-
;;;
;;; --- Package definition.
;;;

(in-package :common-lisp-user)

(macrolet
    ((defconduit (name &body clauses)
       (assert (= 1 (length clauses)))
       (assert (eq (caar clauses) :use))
       (flet ((get-symbols (packages)
                (let (symbols)
                  (with-package-iterator (iterator packages :external)
                    (loop (multiple-value-bind (morep symbol) (iterator)
                            (unless morep (return))
                            (push symbol symbols))))
                  (remove-duplicates symbols :test #'eq))))
         `(defpackage ,name
            (:use #:common-lisp ,@(cdar clauses))
            (:export ,@(get-symbols (cdar clauses)))))))

  (defconduit :iolib
    (:use :io.multiplex :io.streams :net.sockets)))

;; SBCL changes *package* if LOAD-OPing :iolib in the REPL
t
