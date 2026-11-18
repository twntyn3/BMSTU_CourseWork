;;my-range
(define (my-range a b d)
  (if (>= a b)
      '()
      (cons a (my-range (+ a d) b d))))
;; O(n), где n является количеством элементов в генерируемом списке

;;my-flatten

(define (fold-right op init lst)
  (if (null? lst)
      init
      (op (car lst) (fold-right op init (cdr lst)))))

(define (my-flatten lst)
  (cond ((null? lst) '())
        ((not (pair? lst)) (list lst))
        (else (let ((first (my-flatten (car lst)))
                    (rest (my-flatten (cdr lst))))
                (fold-right cons rest first))))) 

;; O(n), где n явялется количеством атомарных элементов в списке

;;my-element?
(define (my-element? x xs)
  (cond ((null? xs) #f)
        ((equal? x (car xs)) #t)
        (else (my-element? x (cdr xs)))))
;; O(n), где n являетася длиной списка

;;my-filter
(define (my-filter pred? xs)
  (cond ((null? xs) '())
        ((pred? (car xs)) (cons (car xs) (my-filter pred? (cdr xs))))
        (else (my-filter pred? (cdr xs)))))
;; O(n), где n — длина списка

;;my-fold-left
(define (my-fold-left op xs)
  (define (helper acc lst)
    (if (null? lst)
        acc
        (helper (op acc (car lst)) (cdr lst))))
  (helper (car xs) (cdr xs)))
;; O(n), где n является длиной списка

;;my-fold-right
(define (my-fold-right op xs)
  (if (null? xs)
      (error "empty list")
      (fold-right (lambda (x acc)
                    (if (null? acc)
                        x
                        (op x acc)))
                  '() 
                  xs)))
;; O(n), где n является длиной списка

;;reverse!
(define (reverse! xs)
  (let loop ((lst xs) (rev '()))
    (if (null? lst)
        rev
        (loop (cdr lst) (cons (car lst) rev)))))
;; O(n), где n является длиной списка

;;append!
(define (append! . lists)
  (let loop ((lst lists))
    (if (null? lst)
        '()
        (let ((first (car lst))
              (rest (cdr lst)))
          (if (null? first)
              (loop rest)
              (begin
                (let find-last ((curr first))
                  (if (null? (cdr curr))
                      (if (null? rest)
                          first
                          (set-cdr! curr (loop rest)))
                      (find-last (cdr curr))))
                first))))))

;; O(n), где n является суммой длин всех непустых списков

;;examples
(my-range 0 11 3) ; '(0 3 6 9)
(my-flatten '((1) 2 (3 (4 5)) 6)) ; '(1 2 3 4 5 6)
(my-element? 1 '(3 2 1)) ; #t
(my-element? 4 '(3 2 1)) ; #f
(my-filter odd? (my-range 0 10 1)) ; '(1 3 5 7 9)
(my-fold-left quotient '(16 2 2 2 2)) ; 1
(my-fold-right expt '(2 3 4)) ; 2417851639229258349412352
(reverse! '(a b c d e)) ; '(e d c b a)
(define xs '(1 2 3))
(define ys '(4 5 6))
(append! xs ys) ; '(1 2 3 4 5 6)
