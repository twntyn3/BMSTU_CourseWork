(define-syntax test
  (syntax-rules ()
    ((_ expr expected-result)
     (list (quote expr) expected-result))))  


(define (run-test test)
  (let ((expr (car test))               
        (expected-result (cadr test)))  
    (let ((result (eval expr (interaction-environment))))
      (if (equal? result expected-result)   
          (begin
            (display expr) (display " ok")
            (newline))
          (begin
            (display expr) (display " FAIL")
            (newline)
            (display "Expected: ") (display expected-result) (newline)
            (display "Returned: ") (display result) (newline))))))

(define (run-tests tests)
  (for-each run-test tests))



;;use-assertion

(define ie (interaction-environment))
(define call/cc call-with-current-continuation)

(define *env* #f)

(define-syntax use-assertions
  (syntax-rules ()
    ((_)
     (call/cc (lambda (cc)
                (set! *env* cc))))))

(define-syntax assert
  (syntax-rules ()
    ((_ expr)
     (if (eval expr ie)
         #t
         (begin
           (display "FAILED: ")
           (*env* (write 'expr)))))))


(use-assertions) 

(define (1/x x)
  (assert (not (zero? x)))
  (/ 1 x))

(map 1/x '(1 2 3 4 5)) 
(map 1/x '(-2 -1 0 1 2))


;;tribonachi
(newline)

(define (trib-without-memo n)
  (cond
    ((<= n 1) 0)
    ((= n 2) 1)
    (else (+ (trib-without-memo (- n 1)) (trib-without-memo (- n 2)) (trib-without-memo (- n 3))))))

(define (trib n)
  (let ((memo (make-vector (+ n 1))))
    (let loop ((num n))
      (cond
        ((< num 2) 0)
        ((= num 2) 1)
        (else (if (zero? (vector-ref memo num))
                  (vector-set! memo num
                               (+ (loop (- num 1))
                                  (loop (- num 2))
                                  (loop (- num 3)))))
              (vector-ref memo num))))))

(trib 32)
(trib-without-memo 32)




;;lazycons
(define-syntax lazy-cons
  (syntax-rules ()
    ((_ a b) (cons a (lambda () b)))))
(define ones (lazy-cons 1 ones))
;;lazycar
(define (lazy-car p)
  (car p))


;;lazycdr
(define (lazy-cdr p)
  ((cdr p)))


;;lazyhead
(define (lazy-head xs k)
  (if (or (zero? k) (null? xs))
      '()
      (cons (lazy-car xs) (lazy-head (lazy-cdr xs) (- k 1)))))
;;lazyref
(define (lazy-ref xs k)
  (if (zero? k)
      (lazy-car xs)
      (lazy-ref (lazy-cdr xs) (- k 1))))

;;lazymap
(define (lazy-map proc xs)
  (if (null? xs)
      '()
      (lazy-cons (proc (lazy-car xs)) (lazy-map proc (lazy-cdr xs)))))

;;lazyzip
(define (lazy-zip xs ys)
  (if (or (null? xs) (null? ys))
      '()
      (lazy-cons (list (lazy-car xs) (lazy-car ys))
                 (lazy-zip (lazy-cdr xs) (lazy-cdr ys)))))

;;Haskel
(define (naturals start)
  (lazy-cons start (naturals (+ start 1))))

(define factorials
  (letrec ((factorials (lazy-cons 1 (lazy-map (lambda (pair)
                                                (* (car pair) (cadr pair)))
                                              (lazy-zip (naturals 1) factorials)))))
    factorials))

(lazy-head factorials 10)
(lazy-ref factorials 5)
(lazy-head factorials 15)


;;while
(newline)
(define-syntax while
  (syntax-rules ()
    ((while cond? expr ...)
     (let loop ()
       (if cond?
           (begin expr ...
                  (loop)))))))

(let ((p 0)
      (q 0))
  (while (< p 3)
         (set! q 0)
         (while (< q 3)
                (display (list p q))
                (newline)
                (set! q (+ q 1)))
         (set! p (+ p 1))))

;;unless
(newline)
(define-syntax unless
  (syntax-rules ()
    ((unless test expr ...)
     (if (not test)
         (begin expr ...)))))
(define x 1)
(unless (= x 0) (display "x != 0") (newline))

;C++
(newline)
(define-syntax cout
  (syntax-rules (<< endl)
    ((cout << endl)
     (newline))
    ((cout << elem)
     (display elem))
    ((cout << endl others ...)
     (begin (newline)
            (cout others ...)))
    ((cout << elem others ...)
     (begin (display elem)
            (cout others ...)))))
(cout << "a = " << 1 << endl << "b = " << 2 << endl)


;;select-rec source dest






;;text-stat source







