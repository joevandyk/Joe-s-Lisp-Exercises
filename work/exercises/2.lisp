(load "check-equal.lisp")
(load "1.lisp")

; Finds the last two elements in the list
(defun my-last-two (lst)
  (if (null (cdr(cdr lst)))
    lst
    (my-last-two (cdr lst))))

(check-equal '(c d) (my-last-two '(a b c d)))
(check-equal '(c d) (my-last-two '(c d)))
(check-equal '(d)   (my-last-two '(d)))
(check-equal '()    (my-last-two '()))

