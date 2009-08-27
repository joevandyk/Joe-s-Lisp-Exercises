(load "check-equal.lisp")

; Finds the last cons cell of a list
(defun my-last (lst)
  (if (null (cdr lst))
    lst
    (my-last (cdr lst))))


(check-equal '(d) (my-last '(a b c d)))
(check-equal '(nil) (my-last '(nil)))
(check-equal '() (my-last '()))
