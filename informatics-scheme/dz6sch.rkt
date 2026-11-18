(define (tokenize expression)
  (define (is-digit? ch)
    (and (char>=? ch #\0) (char<=? ch #\9)))  ; проверка на цифры
  
  (define (is-alpha? ch)
    (char-alphabetic? ch))  ; проверка на буквы

  (define (is-space? ch)  ; проверка на пробел
    (char-whitespace? ch))

  (define (read-number expr)
    (let loop ((input expr) (num ""))
      (if (and (not (null? input)) (or (is-digit? (car input)) (eq? (car input) #\.)))
          (loop (cdr input) (string-append num (string (car input))))
          (values (string->number num) input))))

  (define (read-identifier expr)
    (let loop ((input expr) (name ""))
      (if (and (not (null? input)) (is-alpha? (car input)))
          (loop (cdr input) (string-append name (string (car input))))
          (values (string->symbol name) input))))

  (define (tokenize-helper expr tokens)
    (cond
      ((null? expr) (reverse tokens))  ; возвращаем итоговый список токенов
      ((is-space? (car expr))
       (tokenize-helper (cdr expr) tokens))  ; пропускаем пробелы
      ((is-digit? (car expr))  
       (call-with-values (lambda () (read-number expr))
         (lambda (num rest) (tokenize-helper rest (cons num tokens)))))
      ((is-alpha? (car expr))  
       (call-with-values (lambda () (read-identifier expr))
         (lambda (id rest) (tokenize-helper rest (cons id tokens)))))
      ((char=? (car expr) #\()  
       (tokenize-helper (cdr expr) (cons '"(" tokens)))
      ((char=? (car expr) #\))  
       (tokenize-helper (cdr expr) (cons '")" tokens)))
      ((char=? (car expr) #\+)  
       (tokenize-helper (cdr expr) (cons '+ tokens)))
      ((char=? (car expr) #\-) 
       (tokenize-helper (cdr expr) (cons '- tokens)))
      ((char=? (car expr) #\*)  
       (tokenize-helper (cdr expr) (cons '* tokens)))
      ((char=? (car expr) #\/)  
       (tokenize-helper (cdr expr) (cons '/ tokens)))
      ((char=? (car expr) #\^)  
       (tokenize-helper (cdr expr) (cons '^ tokens)))
      (else #f)))  

  (tokenize-helper (string->list expression) '()))  ; Начало рекурсивного обхода
;testing for 1st task
(tokenize "1")
; ⇒ (1)

(tokenize "-a")
; ⇒ (- a)

(tokenize "-a + b * x^2 + dy")
; ⇒ (- a + b * x ^ 2 + dy)

(tokenize "(a - 1)/(b + 1)")
; ⇒ ("(" a - 1 ")" / "(" b + 1 ")")

(define (parse tokens)
  (define (expr tokens)
    (let ((term-result (term tokens)))
      (expr-helper (car term-result) (cdr term-result))))

  (define (expr-helper left-tree tokens)
    (if (null? tokens)
        (cons left-tree '())
        (let ((op (car tokens)))
          (if (member op '(+ -))
              (let ((term-result (term (cdr tokens))))
                (expr-helper (list left-tree op (car term-result)) (cdr term-result)))
              (cons left-tree tokens)))))

  (define (term tokens)
    (let ((factor-result (factor tokens)))
      (term-helper (car factor-result) (cdr factor-result))))

  (define (term-helper left-tree tokens)
    (if (null? tokens)
        (cons left-tree '())
        (let ((op (car tokens)))
          (if (member op '(* /))
              (let ((factor-result (factor (cdr tokens))))
                (term-helper (list left-tree op (car factor-result)) (cdr factor-result)))
              (cons left-tree tokens)))))

  (define (factor tokens)
    (let ((power-result (power tokens)))
      (factor-helper (car power-result) (cdr power-result))))

  (define (factor-helper left-tree tokens)
    (if (null? tokens)
        (cons left-tree '())
        (let ((op (car tokens)))
          (if (eq? op '^)
              (let ((power-result (power (cdr tokens))))
                (factor-helper (list left-tree op (car power-result)) (cdr power-result)))
              (cons left-tree tokens)))))

  (define (power tokens)
    (let ((token (car tokens)))
      (cond ((eq? token '-)
             (let ((power-result (power (cdr tokens))))
               (cons (list '- (car power-result)) (cdr power-result))))
            ((equal? token "(")
             (let ((expr-result (expr (cdr tokens))))
               (cons (car expr-result) (cdr (cdr expr-result)))))
            (else (cons token (cdr tokens))))))

  (let ((result (expr tokens)))
    (if (null? (cdr result))
        (car result)
        #f)))

(display (parse (tokenize "a/b/c/d")))
(newline)
;; => (((a / b) / c) / d)

(display (parse (tokenize "a^b^c^d")))
(newline)
;; => (a ^ (b ^ (c ^ d)))

(display (parse (tokenize "a/(b/c)")))
(newline)
;; => (a / (b / c))

(display (parse (tokenize "a + b/c^2 - d")))
(newline)
;; => ((a + (b / (c ^ 2))) - d)



(define (tree->scheme tree)
  (cond
    ((number? tree) tree)
    ((symbol? tree) tree)
    ((and (pair? tree) (eq? (car tree) '-) 
          (pair? (cdr tree)) 
          (null? (cddr tree)))
     ;; Унарный минус
     (list '- (tree->scheme (cadr tree))))
    ((and (pair? tree) (pair? (cdr tree)) 
          (pair? (cddr tree)) 
          (null? (cdddr tree)))
     ;; Бинарная операция
     (let ((lhs (tree->scheme (car tree)))
           (op (cadr tree))
           (rhs (tree->scheme (caddr tree))))
       (if (eq? op '^)
           (list 'expt lhs rhs)
           (list op lhs rhs))))
    (else
     (error "Invalid parse tree" tree))))
     
;; Примеры использования:
(display (tree->scheme (parse (tokenize "x^(a + 1)"))))
(newline)
;; => (expt x (+ a 1))

(display (eval (tree->scheme (parse (tokenize "2^2^2^2^2"))) (interaction-environment)))
(newline)
;; => 65536

(tokenize "  - a+b*x ^ 2+dy  ")