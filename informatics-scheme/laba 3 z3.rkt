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






(define (ref sequence index . element)
  (define (solve xs i x)
    (if (= i 0)
        (cons x xs)
        (cons (car xs) 
              (solve (cdr xs) (- i 1) x))))
  (and (>= index 0)
       (cond
        ((pair? sequence)
         (and (if (null? element)
                  (and (< index (length sequence))
                       (list-ref sequence index))
                  (and (<= index (length sequence))
                       (solve sequence index (car element))))))
        ((vector? sequence)
         (and (if (null? element)
                  (and (< index (vector-length sequence))
                       (vector-ref sequence index))
                  (and (<= index (vector-length sequence))
                       (let ((fake-list (vector->list sequence)))
                         (list->vector (solve fake-list index (car element))))))))
        ((string? sequence)
         (and (if (null? element)
                  (and (< index (string-length sequence))
                       (string-ref sequence index))
                  (and (<= index (string-length sequence))
                       (char? (car element))
                       (let ((fake-list (string->list sequence)))
                         (list->string (solve fake-list index (car element)))))))))))


(define tests-3
  (list
   (test (ref '(1 2 3) 1) 2)
   (test (ref #(1 2 3) 1) 2)
   (test (ref "123" 1) #\2)
   (test (ref "123" 3) #f)
   (test (ref '(1 2 3) 1 0) (1 0 2 3))
   (test (ref #(1 2 3) 1 0)  #(1 0 2 3))
   (test (ref #(1 2 3) 1 #\0) #(1 #\0 2 3))
   (test (ref "123" 1 #\0) "1023")
   (test (ref "123" 1 0) #f)
   (test (ref "123" 3 #\4) "1234")
   (test (ref "123" 5 #\4) #f)))

(run-tests tests-3)

#|test3
(ref '(1 2 3) 1)  
(ref '(1 2 3) 1)  
(ref "123" 1)    
(ref "123" 3)    


(ref '(1 2 3) 1 0)  
(ref #(1 2 3) 1 0)  
(ref #(1 2 3) 1 #\0) 
(ref "123" 1 #\0)   
(ref "123" 1 0)     
(ref "123" 3 #\4)   
(ref "123" 5 #\4)


|#


