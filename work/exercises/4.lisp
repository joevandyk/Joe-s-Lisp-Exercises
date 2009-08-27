(load "check-equal.lisp")

; Finds the number of elements in a list
; Not sure if this is the best way to do this.
; I also tend to always use recursion?
(defun number-of-elements (lst)
  ; Sums up the rest of the elements of the list
  (defun current-count (lsta i)
    (if (null lsta)
      i
      (current-count (cdr lsta) (+ 1 i))))
  ; Starts off the list count with 0
  (current-count lst 0 ))


(check-equal 5 (number-of-elements '(1 2 3 4 5)))
(check-equal 3 (number-of-elements '()))
(check-equal 1 (number-of-elements '(1)))
