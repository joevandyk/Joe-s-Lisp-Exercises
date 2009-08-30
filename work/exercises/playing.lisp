
(let ((y 7))
  (defun scope-test (x)
    (list x y)))

; (format t "What is going on ??!")

(defun list+ (lst n)
  (mapcar #'(lambda (x) (+ x n))
          lst))

(let ((counter 0))
  (defun new-id() (incf counter))
  (defun reset-id () (setq counter 0)))


(compile 'new-id)

(defun good-reverse (lst) 
  (labels ((rev (lst acc)
                (if (null lst) acc
                  (rev (cdr lst) (cons (car lst) acc))))) 
    (rev lst nil)))
