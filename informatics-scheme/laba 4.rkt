
(define (exit) (display "#f"))

(define-syntax use-assertions
  (syntax-rules ()
    ((use-assertions)
     (call-with-current-continuation
      (lambda (cont)
        (set! exit cont))))))

(define-syntax assert
  (syntax-rules ()
    ((assert condition)
     (if (not condition)
         (begin
           (display "FAILED: ")
           (write 'condition) 
           (newline)
           (exit))))))

(use-assertions) 

(define (1/x x)
  (assert (not (zero? x))) 
  (/ 1 x)) 


(display (map 1/x '(1 2 3 4 5)))  
(newline)
(map 1/x '(1 2 3 4 5)) 


(display (map 1/x '(-2 -1 0 1 2)))
;;numer 2.2

(define (read-file filename)
  (let ((in-port (open-input-file filename)))
    (let loop ((char (read-char in-port)))
      (if (eof-object? char)
          (begin (close-input-port in-port) '()) 
          (cons char (loop (read-char in-port))))))) 

(define (chars->words char-list)
  (define (is-punctuation? ch)
    (or (char=? ch #\.)
        (char=? ch #\,)
        (char=? ch #\;)
        (char=? ch #\()
        (char=? ch #\))
        (char=? ch #\[)
        (char=? ch #\])
        (char=? ch #\{)
        (char=? ch #\})
        (char=? ch #\|)
        (char=? ch #\\)
        (char=? ch #\/)
        (char=? ch #\?)
        (char=? ch #\!)
        (char=? ch #\$)
        (char=? ch #\%)
        ))
  
  (define (helper chars word result)
    (cond
      ((null? chars)
       (if (null? word) 
           (reverse result)
           (reverse (cons (list->string (reverse word)) result))))
      ((or (char=? (car chars) #\space)
           (char=? (car chars) #\newline)
           (is-punctuation? (car chars))) 
       (if (null? word)
           (helper (cdr chars) word result)
           (helper (cdr chars) '() (cons (list->string (reverse word)) result))))
      (else
       (helper (cdr chars) (cons (car chars) word) result))))
  (helper char-list '() '()))

(define (is-number? ch)
  (and (char? ch) (char<=? #\0 ch #\9)))

(define (is-letter? ch)
  (and (char? ch) (char<=? #\A ch #\z)))

(define (check-type str)
  (define (loop chars ans)
    (cond ((null? chars) ans)
          ((equal? (car chars) #\') 1) 
          ((or (equal? (car chars) #\=) 
               (equal? (car chars) #\+)
               (equal? (car chars) #\*)
               (equal? (car chars) #\/)
               (equal? (car chars) #\%)
               (equal? (car chars) #\>)
               (equal? (car chars) #\<)) 3) 
          ((and (or (= ans 0) (= ans 2)) (is-number? (car chars))) (loop (cdr chars) 2)) 
          ((and (= ans 1) (is-number? (car chars))) 3) 
          ((is-letter? (car chars)) (loop (cdr chars) 1)) 
          (else (loop (cdr chars) ans)))) 
  (loop (string->list str) 0))

(define (text-stat source)
  (define (count-types words counts)
    (if (null? words)
        counts
        (let ((word (car words)))
          (cond ((= (check-type word) 2)
                 (begin (vector-set! counts 1 (+ 1 (vector-ref counts 1)))
                        (count-types (cdr words) counts)))
                ((= (check-type word) 3)
                 (begin (vector-set! counts 2 (+ 1 (vector-ref counts 2)))
                        (count-types (cdr words) counts)))
                (else
                 (begin (vector-set! counts 0 (+ 1 (vector-ref counts 0)))
                        (count-types (cdr words) counts)))))))
  (count-types (chars->words (read-file source)) (vector 0 0 0)))

(text-stat "text.txt")


(text-stat "text.txt")
;;2.1


(define (my-filter pred lst)
  (cond
    ((null? lst) '()) 
    ((pred (car lst))  
     (cons (car lst) (my-filter pred (cdr lst)))) 
    (else (my-filter pred (cdr lst)))))


(define (recursive? fn)
  (and (list? (cadr fn)) (member (caadr fn) (my-flatten (cddr fn)))))





(define (my-flatten lst)
  (cond
    ((null? lst) '())  
    ((list? (car lst))
     (append (my-flatten (car lst)) (my-flatten (cdr lst))))  
    (else (cons (car lst) (my-flatten (cdr lst))))))  


(define (select-rec source dest)
  (with-input-from-file source
    (lambda ()
      (with-output-to-file dest
        (lambda ()
          (let loop ()
            (let ((expr (read)))
              (cond
                ((eof-object? expr)  
                 (display " "))
                ((and (list? expr) (eq? (car expr) 'define) (recursive? expr))
                 
                 (write expr) (newline) (loop))
                (else (loop))))))))))

;; example
;(select-rec "source.scm" "d3st.scm")
;;numer 3 without memo
(define (tribonacci n)
  (cond
    ((= n 0) 0)
    ((= n 1) 0)
    ((= n 2) 1)
    (else (+ (tribonacci (- n 1))
             (tribonacci (- n 2))
             (tribonacci (- n 3))))))
;;numer 3 s memo
(define tribonacci-memo
  (let ((memo (make-vector 1000 #f))) 
    (define (trib n)
      (if (not (vector-ref memo n)) 
          (begin
            (vector-set! memo n 
                         (cond
                           ((= n 0) 0)
                           ((= n 1) 0)
                           ((= n 2) 1)
                           (else (+ (trib (- n 1))
                                    (trib (- n 2))
                                    (trib (- n 3))))))
            (vector-ref memo n) 
            )
          (vector-ref memo n))) 
    trib))

;; sravnenie (3.3)(v console)
(tribonacci 30)
(tribonacci-memo 30)


;zadanie numer 4
;;;;;;;;;;;;;;;;

;;lazy cons
(define-syntax lazy-cons
  (syntax-rules ()
    ((_ a b)
     (cons a (delay b)))))  
;; lazy car

(define (lazy-car p)
  (car p))  
;; lazy cdr

(define (lazy-cdr p)
  (force (cdr p)))  
;; lazy head
(define (lazy-head xs k)
  (if (zero? k)
      '() 
      (cons (lazy-car xs) (lazy-head (lazy-cdr xs) (- k 1))))) 

;; lazy ref
(define (lazy-ref xs k)
  (if (zero? k)
      (lazy-car xs)  
      (lazy-ref (lazy-cdr xs) (- k 1))))  

;; lazy map
(define (lazy-map proc xs)
  (if (null? xs)  
      '()
      (lazy-cons (proc (lazy-car xs)) (lazy-map proc (lazy-cdr xs)))))  

;; lazyzip
(define (lazy-zip xs ys)
  (if (or (null? xs) (null? ys)) 
      '()
      (lazy-cons (list (lazy-car xs) (lazy-car ys))  
                 (lazy-zip (lazy-cdr xs) (lazy-cdr ys)))))  

;ehamples
(define ones (lazy-cons 1 ones))


(display (lazy-head ones 5))  
(newline)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; perevod from haskel langauge;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define naturals
  (lambda (start)
    (lazy-cons start (naturals (+ start 1)))))


(define factorials
  (lazy-cons 1
             (lazy-map (lambda (n-f)
                         (let ((n (car n-f))
                               (f (cadr n-f)))
                           (* n f)))  
                       (lazy-zip (naturals 1) factorials))))  

;ehample
(display (lazy-head factorials 12))
(lazy-head factorials 10)
(lazy-ref factorials 5)
(lazy-head factorials 15)
(newline)




;;задание 5
;;a
(define-syntax unless
  (syntax-rules ()
    ((unless cond? expr1 expr2 ...)
     (if (not cond?)
         (begin expr1 expr2 ...)))))
;aprimer
(define x 1)
(unless (= x 0) (display "x != 0") (newline))
;;b
(define-syntax while
  (syntax-rules ()
    ((while cond? expr1 expr2 ...)
     (letrec ((loop (lambda ()
                      (if cond?
                          (begin
                            expr1
                            expr2 ...
                            (loop))))))
       (loop)))))

(let ((p 0)
      (q 0))
  (while (< p 3)
         (set! q 0)
         (while (< q 3)
                (display (list p q))
                (newline)
                (set! q (+ q 1)))
         (set! p (+ p 1))))
;;c
(define << " ")
(define endl 'endl)
(define (cout . args)
  (for-each print-helper args))
(define (print-helper elem)
  (if (eq? elem endl)
      (newline)      
      (display elem)))

(cout << "a = " << 1 << endl << "b = " << 2 << endl)

(cout << "Первые 12 факториалов:" << endl)
(display (lazy-head factorials 12))





