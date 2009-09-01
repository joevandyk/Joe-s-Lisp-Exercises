(load "check-equal.lisp")

; Finds the number of elements in a list
; Not sure if this is the best way to do this.
; I also tend to always use recursion?
(defun number-of-elements (lst)
  ; Sums up the rest of the elements of the list
  (labels ((current-count (lst i)
                          (if (null lst)
                            i
                            (current-count (cdr lst) (+ 1 i)))))
    ; Starts off the list count with 0
    (current-count lst 0 )))


(check-equal 5 (number-of-elements '(1 2 3 4 5)))
(check-equal 0 (number-of-elements '()))
(check-equal 1 (number-of-elements '(1)))
