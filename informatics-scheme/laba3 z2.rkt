
;; Zadanie 2

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


(define (signum x)
  (cond
    ((< x 0) -1)
    ((= x 0)  1)
    (else     1)))


(define the-tests
  (list (test (signum -2) -1)
        (test (signum  0)  0)
        (test (signum  2)  1)))


(run-tests the-tests)


;; zadanie 3

(define (ref sequence index . element)
  (define (solve xs i x)
    (if (= i 0)
        (cons x xs)
        (cons (car xs) 
              (solve (cdr xs) (- i 1) x))))
  (and
   (>= index 0)
   (cond
     ((pair? sequence)
      (if (null? element)
          (if (< index (length sequence))
              (list-ref sequence index)
              #f)
          (if (<= index (length sequence))
              (solve sequence index (car element))
              #f)))
     ((vector? sequence)
      (if (null? element)
          (if (< index (vector-length sequence))
              (vector-ref sequence index)
              #f)
          (if (<= index (vector-length sequence))
              (let ((fake-list (vector->list sequence)))
                (list->vector (solve fake-list index (car element))))
              #f)))
     ((string? sequence)
      (if (null? element)
          (if (< index (string-length sequence))
              (string-ref sequence index)
              #f)
          (if (and (<= index (string-length sequence)) (char? (car element)))
              (let ((fake-list (string->list sequence)))
                (list->string (solve fake-list index (car element)))
              )
              #f))))))

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



;; Zadanie 4






