(defun dupli (lista int &optional (ini int))
    (cond ((eql lista nil) nil)
          ((<= int 0) (dupli (cdr lista) ini ini))
          (t (cons (car lista) (dupli lista (1- int) ini )))
    )
)