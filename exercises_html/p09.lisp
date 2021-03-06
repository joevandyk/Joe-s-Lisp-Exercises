(defun pack (lista)
	(if (eql lista nil) 
		nil
		(cons (pega lista) (pack (tira lista)))
	)
)

(defun pega (lista)
    (cond ((eql lista nil) nil)
	  ((eql (cdr lista) nil) lista)
          ((equal (car lista) (cadr lista))
              (cons (car lista) (pega (cdr lista))))
          (t (list (car lista)))
    )
)

(defun tira (lista)
    (cond ((eql lista nil) nil)
	  ((eql (cdr lista) nil) nil)
          ((equal (car lista) (cadr lista))
              (tira (cdr lista)))
          (t (cdr lista))
    )
)
