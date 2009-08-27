; There's gotta be a better way to do this
(let ((last-result :success))
  (defun print-result (current-result &rest messages)
    (let ()
      (if (or (equal last-result :failure) 
              (equal current-result :failure))
        (format t "~%"))
      (if (equal current-result :success)
        (format t ".")
        (format t " *** ERROR: ~?" (car messages) (cdr messages)))
      (setq last-result current-result))))

(defun print-success ()
  (print-result :success))

(defun print-failure (expected actual)
  (print-result :failure "Expected ~S, Got ~S" expected actual))

; Checks to see if two things are equal
(defun check-equal (expected actual)
  (if (equal expected actual)
    (print-success)
    (print-failure expected actual)))
