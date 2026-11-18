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


(define-syntax trace
  (syntax-rules ()
    ((trace action)
     (begin
       (write 'action)
       (display " => ")
       (let ((zaza3 action))
         (write zaza3)
         (newline)
         zaza3)))))


(define (zip . xss)
  (if (or (null? xss)
          (null? (trace (car xss))))
      '()
      (cons (map car xss)
            (apply zip (map cdr (trace xss))))))


;; доп проверка на трейсеры
(define counter
  (let ((n 0))
    (lambda ()
      (set! n (+ n 1))
      n)))

(+ (trace (counter))
   (trace (counter)))

(define counter-tests
  (list (test (counter) 3)
        (test (counter) 77) ; ошибка
        (test (counter) 5)))

(run-tests counter-tests)