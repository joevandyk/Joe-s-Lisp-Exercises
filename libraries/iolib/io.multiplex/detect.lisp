;;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; indent-tabs-mode: nil -*-
;;;
;;; --- Detect available multiplexers.
;;;

(in-package :io.multiplex)

;;; TODO: do real detecting here
(setf *default-multiplexer*
      (cdar (sort *available-multiplexers* #'< :key #'car)))
