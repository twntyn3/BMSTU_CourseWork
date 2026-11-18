; Лексический анализатор
;
; Tokens ::= Token Tokens | .
;
; Token ::=
;      Number
;    | Variable
;    | Operator
;    | Parenthesis
;
; Number ::=
;      Digit+
;    | Digit+ '.' Digit+
;    | Digit+ ('e' | 'E') ['+' | '-'] Digit+
;    | Digit+ '.' Digit+ ('e' | 'E') ['+' | '-'] Digit+
;
; Variable ::= Letter+
;
; Operator ::= '+' | '-' | '*' | '/' | '^'
;
; Parenthesis ::= '(' | ')'
;
; Digit ::= '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
;
; Letter ::= 'A' | 'B' | ... | 'Z' | 'a' | 'b' | ... | 'z'

(define (tokenize s)
  ;; s is a string
  ;; returns list of tokens or #f if error
  (let loop ((pos 0)
             (len (string-length s))
             (tokens '()))
    (if (>= pos len)
        (reverse tokens)
        (let ((result (read-token s pos len)))
          (if (or (not result) (eq? result #f))
              #f
              ;; result is (token . next-pos)
              (loop (cdr result) len (cons (car result) tokens)))))))

(define (read-token s pos len)
  (if (>= pos len)
      #f
      (let ((ch (string-ref s pos)))
        (cond
          ;; Пропустить пробелы
          ((char-whitespace? ch)
           (read-token s (+ pos 1) len))
          ;; Круглые скобки
          ((or (char=? ch #\)) (char=? ch #\())
           (cons (string ch) (+ pos 1)))
          ;; Операторы
          ((or (char=? ch #\+)
               (char=? ch #\-)
               (char=? ch #\*)
               (char=? ch #\/)
               (char=? ch #\^))
           (cons (string->symbol (string ch)) (+ pos 1)))
          ;; Число
          ((char-numeric? ch)
           (read-number s pos len))
          ;; Переменная (буквы)
          ((char-alphabetic? ch)
           (read-variable s pos len))
          ;; Недопустимый символ
          (else
           #f)))))

(define (read-number s pos len)
  ;; Возвращает (number . next-pos) или #f
  (let loop ((i pos)
             (number-chars '())))
    (if (>= i len)
        ;; Конец ввода
        (let ((num-str (list->string (reverse number-chars))))
          (parse-number num-str pos i))
        (let ((ch (string-ref s i)))
          (if (or (char-numeric? ch)
                  (char=? ch #\.)
                  (char=? ch #\e)
                  (char=? ch #\E)
                  (and (member ch '(#\+ #\-))
                       (> i pos)
                       (let ((prev (string-ref s (- i 1))))
                         (or (char=? prev #\e) (char=? prev #\E)))))
              (loop (+ i 1) (cons ch number-chars))
              ;; Не число, остановка
              (let ((num-str (list->string (reverse number-chars))))
                (parse-number num-str pos i))))))

(define (parse-number num-str start-pos end-pos)
  ;; num-str – собранная строка числа
  ;; Проверка корректности числа
  (define (valid-number? s)
    (let loop ((i 0) (len (string-length s)) (seen-dot? #f) (seen-e? #f) (seen-digit? #f))
      (if (>= i len)
          seen-digit?
          (let ((ch (string-ref s i)))
            (cond
              ((char-numeric? ch)
               (loop (+ i 1) len seen-dot? seen-e? #t))
              ((char=? ch #\.)
               (if seen-dot?
                   #f ; Повторное '.' не допускается
                   (loop (+ i 1) len #t seen-e? seen-digit?)))
              ((or (char=? ch #\e) (char=? ch #\E))
               (if seen-e?
                   #f ; Повторное 'e/E' не допускается
                   (if (and (>= (+ i 1) len)
                            (not (char-numeric? (string-ref s (+ i 1)))))
                       #f ; 'e' в конце или без цифр после
                       (loop (+ i 1) len seen-dot? #t seen-digit?))))
              ((or (char=? ch #\+) (char=? ch #\-))
               (if (and seen-e?
                        (> i 0)
                        (or (char=? (string-ref s (- i 1)) #\e)
                            (char=? (string-ref s (- i 1)) #\E)))
                   (loop (+ i 1) len seen-dot? seen-e? seen-digit?)
                   #f))
              (else
               #f))))))
  (if (and (not (char=? (string-ref num-str 0) #\+))
           (not (char=? (string-ref num-str 0) #\-))
           (valid-number? num-str))
      (let ((num (string->number num-str)))
        (if num
            (cons num end-pos)
            #f))
      #f))



; Синтаксический анализатор
;
; Expr    ::= Term Expr' .
; Expr'   ::= AddOp Term Expr' | .
; Term    ::= Factor Term' .
; Term'   ::= MulOp Factor Term' | .
; Factor  ::= Power Factor' .
; Factor' ::= PowOp Power Factor' | .
; Power   ::= value | "(" Expr ")" | unaryMinus Power .
;
; value ::= number | variable
; AddOp ::= '+' | '-'
; MulOp ::= '*' | '/'
; PowOp ::= '^'
; unaryMinus ::= '-'

(define (parse tokens)
  (let ((result (parse-Expr tokens)))
    (if (and result (null? (cdr result)))
        (car result)
        #f)))

(define (parse-Expr tokens)
  ;; Expr ::= Term Expr'
  (let ((result (parse-Term tokens)))
    (if result
        (parse-Expr'-aux (car result) (cdr result))
        #f)))

(define (parse-Expr'-aux lhs tokens)
  ;; Expr' ::= AddOp Term Expr' | .
  (if (and (pair? tokens) (AddOp? (car tokens)))
      (let ((op (car tokens))
            (rest (cdr tokens)))
        (let ((result (parse-Term rest)))
          (if result
              (parse-Expr'-aux (list lhs op (car result)) (cdr result))
              #f)))
      ;; Иначе Expr' ::= .
      (cons lhs tokens)))

(define (parse-Term tokens)
  ;; Term ::= Factor Term'
  (let ((result (parse-Factor tokens)))
    (if result
        (parse-Term'-aux (car result) (cdr result))
        #f)))

(define (parse-Term'-aux lhs tokens)
  ;; Term' ::= MulOp Factor Term' | .
  (if (and (pair? tokens) (MulOp? (car tokens)))
      (let ((op (car tokens))
            (rest (cdr tokens)))
        (let ((result (parse-Factor rest)))
          (if result
              (parse-Term'-aux (list lhs op (car result)) (cdr result))
              #f)))
      ;; Иначе Term' ::= .
      (cons lhs tokens)))

(define (parse-Factor tokens)
  ;; Factor ::= Power Factor'
  (let ((result (parse-Power tokens)))
    (if result
        (parse-Factor'-aux (car result) (cdr result))
        #f)))

(define (parse-Factor'-aux lhs tokens)
  ;; Factor' ::= PowOp Power Factor' | .
  (if (and (pair? tokens) (PowOp? (car tokens)))
      (let ((op (car tokens))
            (rest (cdr tokens)))
        (let ((result (parse-Power rest)))
          (if result
              (parse-Factor'-aux (list lhs op (car result)) (cdr result))
              #f)))
      ;; Иначе Factor' ::= .
      (cons lhs tokens)))

(define (parse-Power tokens)
  ;; Power ::= value | "(" Expr ")" | unaryMinus Power
  (if (null? tokens)
      #f
      (let ((token (car tokens)))
        (cond
          ;; Значение
          ((value? token)
           (cons token (cdr tokens)))
          ;; "(" Expr ")"
          ((and (string? token) (string=? token "("))
           (let ((result (parse-Expr (cdr tokens))))
             (if result
                 (if (and (pair? (cdr result))
                          (string? (car (cdr result)))
                          (string=? (car (cdr result)) ")"))
                     (cons (car result) (cddr result)) ; удаляем ')'
                     #f)
                 #f)))
          ;; Унарный минус
          ((and (symbol? token) (eq? token '-))
           (let ((result (parse-Power (cdr tokens))))
             (if result
                 (cons (list '- (car result)) (cdr result))
                 #f)))
          (else
           #f)))))

(define (AddOp? token)
  (and (symbol? token) (member token '(+ -))))

(define (MulOp? token)
  (and (symbol? token) (member token '(* /))))

(define (PowOp? token)
  (and (symbol? token) (eq? token '^)))

(define (value? token)
  (or (number? token)
      (symbol? token)))

; Преобразователь дерева разбора в выражение на Scheme

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

; Пример использования
; Добавьте следующие строки для проверки работы программы:

;; Лексический анализ
;(tokenize "1")
; ⇒ (1)

;(tokenize "-a")
; ⇒ (- a)

;(tokenize "-a + b * x^2 + dy")
; ⇒ (- a + b * x ^ 2 + dy)

;(tokenize "(a - 1)/(b + 1)")
; ⇒ ("(" a - 1 ")" / "(" b + 1 ")")

;; Синтаксический анализ
;(parse (tokenize "a/b/c/d"))
; ⇒ (((a / b) / c) / d)

;(parse (tokenize "a^b^c^d"))
; ⇒ (a ^ (b ^ (c ^ d)))

;(parse (tokenize "a/(b/c)"))
; ⇒ (a / (b / c))

;(parse (tokenize "a + b/c^2 - d"))
; ⇒ ((a + (b / (c ^ 2))) - d)

;; Преобразование в Scheme выражение
;(tree->scheme (parse (tokenize "x^(a + 1)")))
; ⇒ (expt x (+ a 1))

;(eval (tree->scheme (parse (tokenize "2^2^2^2")))
;      (interaction-environment))
; ⇒ 65536

; Вы можете раскомментировать эти строки для тестирования.
