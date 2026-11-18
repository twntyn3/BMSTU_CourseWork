; Лексический анализатор
(define error #f)
(define (tokenize expression)
  (define (is-digit? ch)
    (and (char>=? ch #\0) (char<=? ch #\9)))  ; проверка на цифры

  (define (is-alpha? ch)
    (char-alphabetic? ch))  ; проверка на буквы

  (define (is-space? ch)  ; проверка на пробел
    (char-whitespace? ch))

  (define (read-number expr)
    ;; Возвращает (number . rest) или #f
    (let loop ((input expr)
               (num "")
               (seen-dot? #f)
               (seen-e? #f)
               (seen-digit? #f)
               (after-e? #f)
               (after-sign? #f))
      (if (null? input)
          (if (and seen-digit? (or (not seen-e?) after-e?))
              (cons (string->number num) input)
              #f)
          (let ((ch (car input)))
            (cond
              ((is-digit? ch)
               (if seen-e?
                   (loop (cdr input) (string-append num (string ch))
                         seen-dot? seen-e? seen-digit? #t after-sign?)
                   (loop (cdr input) (string-append num (string ch))
                         seen-dot? seen-e? #t after-e? after-sign?)))
              ((char=? ch #\.)
               (if (or seen-dot? seen-e?)
                   #f  ; Точка может быть только один раз и до 'e'
                   (loop (cdr input) (string-append num (string ch))
                         #t seen-e? seen-digit? after-e? after-sign?)))
              ((or (char=? ch #\e) (char=? ch #\E))
               (if (or seen-e? (not seen-digit?))
                   #f  ; Повторное 'e' или 'e' без цифр перед ним
                   (let ((next-input (cdr input)))
                     (if (null? next-input)
                         #f
                         (let ((next-ch (car next-input)))
                           (if (or (is-digit? next-ch)
                                   (member next-ch (list #\+ #\-)))
                               (loop (cdr input)
                                     (string-append num (string ch)) seen-dot? #t seen-digit? #f after-sign?)
                               #f))))))
              ((or (char=? ch #\+) (char=? ch #\-))
               (if (and seen-e? (not after-sign?)
                        (or (equal? (string-ref num (- (string-length num) 1)) #\e)
                            (equal? (string-ref num (- (string-length num) 1)) #\E)))
                   (loop (cdr input) (string-append num (string ch)) seen-dot? seen-e? seen-digit? #f #t)
                   (if seen-digit?
                       (cons (string->number num) input)
                       #f)))
              ((or (is-alpha? ch) (char=? ch #\_))
               (if (and seen-digit? (not seen-e?))
                   #f  ; Буква после числа без разделителя
                   (cons (string->number num) input)))
              (else
               (if (and seen-digit? (or (not seen-e?) after-e?))
                   (cons (string->number num) input)
                   #f)))))))
(define (string-downcase str)
  (list->string (map char-downcase (string->list str))))


(define (read-identifier expr)
  ;; Возвращает (identifier . rest) или #f
  (let loop ((input expr) (name ""))
    (if (and (not (null? input)) (or (is-alpha? (car input)) (char=? (car input) #\_)))
        (loop (cdr input) (string-append name (string (car input))))
        (if (not (string=? name ""))
            (cons (string->symbol (string-downcase name)) input)
            #f))))

  (define (tokenize-helper expr tokens)
    (cond
      ((null? expr) (reverse tokens))
      ((is-space? (car expr))
       (tokenize-helper (cdr expr) tokens))
      ((is-digit? (car expr))
       (let ((result (read-number expr)))
         (if result
             (let ((num (car result))
                   (rest (cdr result)))
               (if (and (not (null? rest)) (is-alpha? (car rest)))
                   #f  ; После числа не может идти буква без разделителя
                   (tokenize-helper rest (cons num tokens))))
             #f)))
      ((is-alpha? (car expr))
       (let ((result (read-identifier expr)))
         (if result
             (let ((id (car result))
                   (rest (cdr result)))
               (if (and (not (null? rest)) (is-digit? (car rest)))
                   #f  ; Идентификатор не может содержать цифры
                   (tokenize-helper rest (cons id tokens))))
             #f)))
      ((char=? (car expr) #\()
       (tokenize-helper (cdr expr) (cons "(" tokens)))
      ((char=? (car expr) #\))
       (tokenize-helper (cdr expr) (cons ")" tokens)))
      ((member (car expr) (list #\+ #\- #\* #\/ #\^))
       (tokenize-helper (cdr expr) (cons (string->symbol (string (car expr))) tokens)))
      (else #f)))

  (tokenize-helper (string->list expression) '()))

;; Парсер
(define (parse tokens)
  (define (expr tokens)
    (let ((term-result (term tokens)))
      (if term-result
          (expr-helper (car term-result) (cdr term-result))
          #f)))

  (define (expr-helper left-tree tokens)
    (if (null? tokens)
        (cons left-tree '())
        (let ((op (car tokens)))
          (if (member op '(+ -))
              (let ((term-result (term (cdr tokens))))
                (if term-result
                    (expr-helper (list left-tree op (car term-result)) (cdr term-result))
                    #f))
              (cons left-tree tokens)))))

  (define (term tokens)
    (let ((factor-result (factor tokens)))
      (if factor-result
          (term-helper (car factor-result) (cdr factor-result))
          #f)))

  (define (term-helper left-tree tokens)
    (if (null? tokens)
        (cons left-tree '())
        (let ((op (car tokens)))
          (if (member op '(* /))
              (let ((factor-result (factor (cdr tokens))))
                (if factor-result
                    (term-helper (list left-tree op (car factor-result)) (cdr factor-result))
                    #f))
              (cons left-tree tokens)))))

  (define (factor tokens)
    (let ((power-result (power tokens)))
      (if power-result
          (factor-helper (car power-result) (cdr power-result))
          #f)))

  (define (factor-helper left-tree tokens)
    (if (and (not (null? tokens)) (eq? (car tokens) '^))
        (let ((factor-result (factor (cdr tokens))))
          (if factor-result
              (cons (list left-tree '^ (car factor-result)) (cdr factor-result))
              #f))
        (cons left-tree tokens)))

  (define (power tokens)
    (if (null? tokens)
        #f
        (let ((token (car tokens)))
          (cond
            ((eq? token '-)
             (let ((power-result (power (cdr tokens))))
               (if power-result
                   (cons (list '- (car power-result)) (cdr power-result))
                   #f)))
            ((equal? token "(")
             (let ((expr-result (expr (cdr tokens))))
               (if (and expr-result
                        (not (null? (cdr expr-result)))
                        (equal? (car (cdr expr-result)) ")"))
                   (cons (car expr-result) (cdr (cdr expr-result)))
                   #f)))
            ((or (number? token) (symbol? token))
             (cons token (cdr tokens)))
            (else #f)))))

  (let ((result (expr tokens)))
    (if (and result (null? (cdr result)))
        (car result)
        #f)))

;; Преобразователь дерева разбора в выражение на Scheme
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
;testing for 1st task
(tokenize "1")
; ⇒ (1)

(tokenize "-a")
; ⇒ (- a)

(tokenize "-a + b * x^2 + dy")
; ⇒ (- a + b * x ^ 2 + dy)

(tokenize "(a - 1)/(b + 1)")
; ⇒ ("(" a - 1 ")" / "(" b + 1 ")")

;tetsting 2nd task
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
;testing 3rd task
(display (tree->scheme (parse (tokenize "x^(a + 1)"))))
(newline)
;; => (expt x (+ a 1))

(display (eval (tree->scheme (parse (tokenize "2^2^2^2"))) (interaction-environment)))
(newline)
;; => 65536
