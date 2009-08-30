; Checks to see if two things are equal
(defun check-equal (expected actual)
  (if (equal expected actual)
    (format t ".")
    (format t "Expected ~S, Got ~S" expected actual)))
