;; дефолт проверка
(define (digit? c)
  (and (char>=? c #\0) (char<=? c #\9)))

(define (sign? c)
  (or (char=? c #\+) (char=? c #\-)))

;; является ли строка допустимой дробью
(define (valid-dec? str)
  (let loop ((chars (string->list str)) (state 'start) (has-dot? #f) (has-fraction? #f))
    (cond
      ((null? chars) (and has-dot? has-fraction?))
      ((eq? state 'start)
       (and (cond
              ((sign? (car chars))
               (and (not (null? (cdr chars)))
                    (not (char=? (car (cdr chars)) #\.))
                    (loop (cdr chars) 'int has-dot? has-fraction?)))
              ((digit? (car chars)) (loop (cdr chars) 'int has-dot? has-fraction?))
              (else #f))))
      ((eq? state 'int)
       (and (cond
              ((digit? (car chars)) (loop (cdr chars) 'int has-dot? has-fraction?))
              ((char=? (car chars) #\.)
               (and (not (null? (cdr chars)))
                    (loop (cdr chars) 'frac #t has-fraction?)))
              (else #f))))
      ((eq? state 'frac)
       (and (cond
              ((digit? (car chars)) (loop (cdr chars) 'frac has-dot? #t))
              (else #f)))))))

;; являются ли все допустимыми дробями
(define (valid-many-decs? str)
  (let ((tokens (split-string str)))
    (and (not (null? tokens))
         (let loop ((tokens tokens))
           (or (null? tokens)
               (and (valid-dec? (car tokens)) (loop (cdr tokens))))))))

;; токены

(define (split-string str)
  (let loop ((chars (string->list str)) (tokens '()) (current-token '()))
    (cond
      ((null? chars)
       (reverse (if (null? current-token)
                    tokens
                    (cons (list->string (reverse current-token)) tokens))))
      ((and (or (char=? (car chars) #\+) (char=? (car chars) #\-))
            (not (null? current-token)))
       (loop chars
             (cons (list->string (reverse current-token)) tokens)
             '()))
      ((or (char=? (car chars) #\space) (char=? (car chars) #\tab) (char=? (car chars) #\newline))
       (loop (cdr chars)
             (if (null? current-token)
                 tokens
                 (cons (list->string (reverse current-token)) tokens))
             '()))
      (else
       (loop (cdr chars) tokens (cons (car chars) current-token))))))

;; разделение строки на токены

(define (scan-dec str)
  (and (valid-dec? str)
       (string->number-custom str)))

(define (string->number-custom str)
  (let loop ((chars (string->list str)) (state 'int) (result 0.0) (sign 1) (fraction-scale 1))
    (cond
      ((null? chars) (exact->inexact (* sign result)))
      ((eq? state 'int)
       (and (cond
              ((char=? (car chars) #\+) (loop (cdr chars) 'int result sign fraction-scale))
              ((char=? (car chars) #\-) (loop (cdr chars) 'int result -1 fraction-scale))
              ((digit? (car chars))
               (loop (cdr chars) 'int (+ (* result 10) (- (char->integer (car chars)) (char->integer #\0)))
                     sign fraction-scale))
              ((char=? (car chars) #\.) (loop (cdr chars) 'frac result sign 10))
              (else #f))))
      ((eq? state 'frac)
       (and (cond
              ((digit? (car chars))
               (loop (cdr chars) 'frac (+ result (/ (- (char->integer (car chars)) (char->integer #\0)) fraction-scale))
                     sign (* fraction-scale 10)))
              (else #f)))))))



;; разделение строки на последовательности дробей
(define (scan-many-decs str)
  (let ((tokens (split-string str)))
    (let loop ((tokens tokens) (results '()))
      (if (null? tokens)
          (reverse results)
          (let ((value (scan-dec (car tokens))))
            (and value (loop (cdr tokens) (cons value results))))))))

;; парсер 
(define (parse tokens)
  (define (parse-body tokens)
    (cond
      ((null? tokens) '())
      ((and (symbol? (car tokens)) (not (member (car tokens) '(if else endif define end))))
       (cons (car tokens) (parse-body (cdr tokens))))
      ((equal? (car tokens) 'if)
       (let ((if-block (parse-if tokens)))
         (if if-block
             (cons if-block (parse-body (cdr tokens)))
             #f)))
      (else '())))

  (define (parse-if tokens)
    (let* ((condition (parse-body (cdr tokens)))
           (else-part (and condition (member 'else tokens) (parse-body (cdr (member 'else tokens)))))
           (endif (and condition (member 'endif tokens) (cdr (member 'endif tokens)))))
      (and endif (list 'if condition else-part))))

  (define (parse-define tokens)
    (and (symbol? (car tokens))
         (equal? (cadr tokens) '--)
         (list (car tokens) (parse-body (cddr tokens)))))

  ;; парсим парсим
  (let ((result (parse-body tokens)))
    (and result (list result))))

;; основные функции (гроб)
(define (parse-article s)
  (let* (
      (define-keyword (and (equal? (peek s) 'define) (pop s)))
      (name (and define-keyword (symbol? (peek s)) (pop s)))
      (body (and name (parse-body s)))
      (end-keyword (and body (equal? (peek s) 'end) (pop s))))
    (and end-keyword (list 'define name body))))

(define (parse-articles s)
  (if (equal? (peek s) 'define)
      (let ((curr (parse-article s))
            (next (parse-articles s)))
        (and curr next (cons curr next)))
      '()))


(define (parse-body s)
  (let* (
          (borders (list 'endif 'end))
          (parsed
              (cond 
                  ((or (not (peek s)) (member (peek s) borders)) '())
                  ((equal? (peek s) 'if)
                   (let ((if-result (parse-conditional s)))
                     (and if-result (append (list if-result) (parse-body s)))))
                  ((or (integer? (peek s)) (symbol? (peek s)))
                   (cons (pop s) (parse-body s)))
                  (else #f))))
    (and parsed (not (member #f parsed)) parsed)))

(define (parse-conditional s)
  (let* (
      (opening (and (equal? (peek s) 'if) (pop s)))
      (condition (and opening (parse-body s)))
      (else-part (and condition (equal? (peek s) 'else) (parse-elsepart s)))
      (endif (and condition (equal? (peek s) 'endif) (pop s))))
    (and endif (list 'if condition else-part))))

(define (make-stream lst) (list lst '()))
(define (peek s) (if (null? (car s)) #f (car (car s))))
(define (pop s) 
  (let ((next (peek s)))
    (if next (set-car! s (cdr (car s))))
    next))


(define (parse-program s)
  (let* (
      (articles (parse-articles s))
      (body (and articles (parse-body s))))
    (and body (not (member #f body)) (not (member #f articles)) (list articles body))))


(define (parse s) 
  (parse-program (make-stream (vector->list s))))

(define (valid? s) 
  (not (not (parse s))))

;; тесты
(valid-dec? "7234.4")  ;⇒ #t
(valid-dec? "+07.70")  ;⇒ #t
(valid-dec? "-4.111")  ;⇒ #t
(valid-dec? "+.7777")  ;⇒ #f
(valid-dec? "5555.")   ;⇒ #f
(valid-dec? "10")      ;⇒ #f
(newline)

(valid-many-decs?
 "\t1.8 -2.4\n\n5.0")  ;⇒ #t
(valid-many-decs?
 "\t1.8 -2.4\n\n5.-")  ;⇒ #f
(valid-many-decs?
 "-568.3+77.1")        ;⇒ #t
(newline)

(scan-dec "7234.4")    ;⇒ 7234.4
(scan-dec "+07.70")    ;⇒ 7.7
(scan-dec "-4.111")    ;⇒ -4.111
(scan-dec "+.7777")    ;⇒ #f
(scan-dec "5555.")     ;⇒ #f
(scan-dec "10")        ;⇒ #f
(newline)


(scan-many-decs
 "\t1.8 -2.4\n\n5.0")  ;⇒ (1.8 -2.4 5.0)
(scan-many-decs
 "\t1.8 -2.4\n\n5.-")  ;⇒ #f
(scan-many-decs
 "-568.3+77.1")        ;⇒ (-568.3 77.1)
(newline)


(valid? #(1 2 +))                 ;⇒ #t
(valid? #(define 1 2 end))        ;⇒ #f
(valid? #(define x if end endif)) ;⇒ #f
(newline)

(parse #(1 2 +)) ;⇒ (() (1 2 +))
(parse #(x dup 0 swap if drop -1 endif))
    ;⇒ (() (x dup 0 swap (if (drop -1))))
(parse #(x dup 0 swap if drop -1 else swap 1 + endif))
    ;⇒ (() (x dup 0 swap (if (drop -1) (swap 1 +))))

(parse #( define -- 1 - end
          define =0? dup 0 = end
          define =1? dup 1 = end
          define factorial
              =0? if drop 1 exit endif
              =1? if drop 1 exit endif
              dup --
              factorial
              *
          end
          0 factorial
          1 factorial
          2 factorial
          3 factorial
          4 factorial ))
 #|⇒
 (((-- (1 -))
   (=0? (dup 0 =))
   (=1? (dup 1 =))
   (factorial
    (=0? (if (drop 1 exit)) =1? (if (drop 1 exit)) dup -- factorial *)))
  (0 factorial 1 factorial 2 factorial 3 factorial 4 factorial))|#

(parse #( define -- 1 - end
          define =0? dup 0 = end
          define =1? dup 1 = end
          define factorial
              =0? if
                  drop 1
              else =1? if
                  drop 1
              else
                  dup --
                  factorial
                  *
              endif
              endif
          end
          0 factorial
          1 factorial
          2 factorial
          3 factorial
          4 factorial ))
 #|⇒
 (((-- (1 -))
   (=0? (dup 0 =))
   (=1? (dup 1 =))
   (factorial
    (=0? (if (drop 1)(=1? (if (drop 1) (dup -- factorial *)))))))
  (0 factorial 1 factorial 2 factorial 3 factorial 4 factorial))|#

(parse #(define word w1 w2 w3)) ;⇒ #f
