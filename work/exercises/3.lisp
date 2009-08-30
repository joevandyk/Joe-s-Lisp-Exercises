(load "check-equal.lisp")

; Gets the x'th value of a list, starting at one
(defun element-at (lst index)
  (if (equal 1 index)
    (car lst)
    (element-at (cdr lst) (- index 1))))

(check-equal (element-at '(1 2 3) 1) 1)
(check-equal (element-at '(1 2 3) 2) 2)
(check-equal (element-at '(1 2 3) 3) 3)
