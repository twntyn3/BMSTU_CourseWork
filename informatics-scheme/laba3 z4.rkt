(define-syntax test
  (syntax-rules()
    ((tst proced res) '(proced res))))

(define (run-test test)
  (write (car test))
  (define c-res (eval (car test) (interaction-environment)))
  (if (equal? c-res (cadr test))
      (begin
        (display "ok!!!#\newline")
        #t)      
      (begin
        (display "fail#\newline")
        (display "  Expected:")
        (write (cadr test))
        (newline)
        (display "  Returned:")
        (write c-res)
        (newline)
        #f)))

(define (run-tests tests)
  (if (null? (cdr tests))
      (run-test (car tests))
      ((lambda (x y) 
         (and x y))
       (run-test (car tests))
       (run-tests (cdr tests)))))






(define (if->cond data)
  (if (and (list? data) (equal? (car data) 'if)) 
      (let ((condition (cadr data))
            (true_value (caddr data))
            (false_value (if (null? (cdddr data)) 
                             '() 
                             (cadddr data))))
        (cond
          ((null? false_value)
           `(cond (,condition ,true_value)))
          ((and (list? false_value) (equal? (car false_value) 'if))
           `(cond (,condition ,true_value)
                  ,@(cdr (if->cond false_value))))
          (else `(cond (,condition ,true_value) (else ,false_value)))))
      data)) 


(define tests-4
  (list
   (test (if->cond '(if (> x 0)
                        +1
                        (if (< x 0)
                            -1
                            0)))
         (cond ((> x 0) +1) ((< x 0) -1) (else 0)))
   (test (if->cond '(if (equal? (car expr) 'lambda)
                        (compile-lambda expr)
                        (if (equal? (car expr) 'define)
                            (compile-define expr)
                            (if (equal? (car expr) 'if)
                                (compile-if expr)))))
         (cond ((equal? (car expr) 'lambda) (compile-lambda expr))
               ((equal? (car expr) 'define) (compile-define expr))
               ((equal? (car expr) 'if) (compile-if expr))))
   (test (if->cond '(if a
               aa
       (if b
           bb
           (if c
               cc
           dd))))
         (cond (a aa) (b bb) (c cc) (else dd)))
   (test (if->cond '(if a
               aa
       (if b
           bb
           (if c
               cc))))
         (cond (a aa) (b bb) (c cc)))
   (test (if->cond '(if (> x 0)
               (display '+)
       (if (= x 0)
           (display 0)
           (display '-))))
         (cond ((> x 0) (display '+))
         ((= x 0) (display 0))
     (else (display '-))))
   (test (if->cond '(if (< d 0)
               (list)
       (if (= d 0)
           (list x)
           (list x1 x2))))
         (cond ((< d 0) (list))
         ((= d 0) (list x))
     (else (list x1 x2))))))

(run-tests tests-4)








 #|test4

(if->cond '(if (> x 0)
               +1
               (if (< x 0)
                   -1
                   0)))

(if->cond '(if (equal? (car expr) 'lambda)
               (compile-lambda expr)
               (if (equal? (car expr) 'define)
                   (compile-define expr)
                   (if (equal (car expr) 'if)
                       (compile-if expr)))))

(if->cond '(if a
               aa
       (if b
           bb
           (if c
               cc
           dd))))

(if->cond '(if a
               aa
       (if b
           bb
           (if c
               cc))))

(if->cond '(if (> x 0)
               (display '+)
       (if (= x 0)
           (display 0)
           (display '-))))

(if->cond '(if (< d 0)
               (list)
       (if (= d 0)
           (list x)
           (list x1 x2))))



|#