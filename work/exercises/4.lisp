(load "check-equal.lisp")

; Finds the number of elements in a list

(defun number-of-elements (lst)
  (defun current-count (lsta i)
    (if null (lsta)
      i
      (current-count (cdr lsta) (+ 1 i))))
  (current-count (lst 0)))


(check-equal 5 (number-of-elements '(1 2 3 4 5)))
(check-equal 0 (number-of-elements '()))
(check-equal 1 (number-of-elements '(1)))
