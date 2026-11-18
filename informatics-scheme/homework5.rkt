(define (interpret program stack)
  (define (execute words idx stack return-stack dictionary loop-stack)
    (if (>= idx (vector-length words))
        stack
        (let ((word (vector-ref words idx)))
          (cond
            ((integer? word)
             (execute words (+ idx 1) (cons word stack) return-stack dictionary loop-stack))

            ;; Арифметические операции
            ((eq? word '+)
             (execute-binop words idx stack return-stack dictionary loop-stack +))
            ((eq? word '-)
             (execute-binop words idx stack return-stack dictionary loop-stack -))
            ((eq? word '*)
             (execute-binop words idx stack return-stack dictionary loop-stack *))
            ((eq? word '/)
             (execute-binop-checked words idx stack return-stack dictionary loop-stack quotient))
            ((eq? word 'mod)
             (execute-binop-checked words idx stack return-stack dictionary loop-stack modulo))
            ((eq? word 'neg)
             (execute-unop words idx stack return-stack dictionary loop-stack -))

            ;; Логические операции
            ((eq? word '=)
             (execute-binop words idx stack return-stack dictionary loop-stack
                            (lambda (a b) (if (= a b) -1 0))))
            ((eq? word '<)
             (execute-binop words idx stack return-stack dictionary loop-stack
                            (lambda (a b) (if (< a b) -1 0))))
            ((eq? word '>)
             (execute-binop words idx stack return-stack dictionary loop-stack
                            (lambda (a b) (if (> a b) -1 0))))
            ((eq? word 'not)
             (execute-unop words idx stack return-stack dictionary loop-stack
                           (lambda (a) (if (zero? a) -1 0))))
            ((eq? word 'and)
             (execute-binop words idx stack return-stack dictionary loop-stack
                            (lambda (a b) (if (and (not (zero? a)) (not (zero? b))) -1 0))))
            ((eq? word 'or)
             (execute-binop words idx stack return-stack dictionary loop-stack
                            (lambda (a b) (if (or (not (zero? a)) (not (zero? b))) -1 0))))

            ;; Операции со стеком
            ((eq? word 'drop)
             (execute-stack-op words idx stack return-stack dictionary loop-stack
                               (lambda (s) (cdr s))))
            ((eq? word 'swap)
             (execute-stack-op words idx stack return-stack dictionary loop-stack
                               (lambda (s) (cons (cadr s) (cons (car s) (cddr s))))))
            ((eq? word 'dup)
             (execute-stack-op words idx stack return-stack dictionary loop-stack
                               (lambda (s) (cons (car s) s))))
            ((eq? word 'over)
             (execute-stack-op words idx stack return-stack dictionary loop-stack
                               (lambda (s) (cons (cadr s) s))))
            ((eq? word 'rot)
             (execute-stack-op words idx stack return-stack dictionary loop-stack
                               (lambda (s) (cons (caddr s)
                                                 (cons (cadr s)
                                                       (cons (car s) (cdddr s)))))))
            ((eq? word 'depth)
             ;; Исправлено: непосредственно выполняем операцию без проверки на пустой стек
             (execute words (+ idx 1)
                      (cons (length stack) stack)
                      return-stack dictionary loop-stack))

            ;; Управляющие конструкции
            ((eq? word 'define)
             (let ((name (vector-ref words (+ idx 1))))
               (let loop ((i (+ idx 2)))
                 (if (or (>= i (vector-length words)) (eq? (vector-ref words i) 'end))
                     (execute words (+ i 1) stack return-stack
                              (cons (list name 'func (+ idx 2)) dictionary) loop-stack)
                     (loop (+ i 1))))))
            ((eq? word 'end)
             (if (null? return-stack)
                 stack
                 (execute words (car return-stack) stack (cdr return-stack) dictionary loop-stack)))
            ((eq? word 'exit)
             (if (null? return-stack)
                 stack
                 (execute words (car return-stack) stack (cdr return-stack) dictionary loop-stack)))
            ((eq? word 'if)
             (if (zero? (car stack))
                 (let loop ((i (+ idx 1)))
                   (if (or (>= i (vector-length words)) (eq? (vector-ref words i) 'endif))
                       (execute words (+ i 1) (cdr stack) return-stack dictionary loop-stack)
                       (loop (+ i 1))))
                 (execute words (+ idx 1) (cdr stack) return-stack dictionary loop-stack)))
            ((eq? word 'endif)
             (execute words (+ idx 1) stack return-stack dictionary loop-stack))

            ;; Циклы
            ((eq? word 'while)
             (let ((end-idx (find-matching 'wend idx words)))
               (if (zero? (car stack))
                   (execute words (+ end-idx 1) (cdr stack) return-stack dictionary loop-stack)
                   (execute words (+ idx 1) (cdr stack) (cons idx return-stack) dictionary
                            (cons end-idx loop-stack)))))
            ((eq? word 'wend)
             (execute words (car return-stack) stack
                      (cdr return-stack) dictionary (cdr loop-stack)))

            ;; Операторы break и continue
            ((eq? word 'break)
             (if (null? loop-stack)
                 (error "'break' used outside of a loop")
                 (execute words (+ (car loop-stack) 1) stack return-stack dictionary (cdr loop-stack))))
            ((eq? word 'continue)
             (if (null? loop-stack)
                 (error "'continue' used outside of a loop")
                 (execute words (car return-stack) stack return-stack dictionary loop-stack)))

            ;; Глобальные переменные
            ((eq? word 'defvar)
             (let ((name (vector-ref words (+ idx 1)))
                   (value (vector-ref words (+ idx 2))))
               (if (assoc name dictionary)
                   (error "Variable or function already defined")
                   (execute words (+ idx 3) stack return-stack
                            (cons (list name 'var value) dictionary) loop-stack))))
            ((eq? word 'set)
             (let ((name (vector-ref words (+ idx 1))))
               (if (assoc name dictionary)
                   (if (eq? (cadr (assoc name dictionary)) 'var)
                       (let ((value (car stack)))
                         (execute words (+ idx 2) (cdr stack) return-stack
                                  (cons (list name 'var value)
                                        (remove-assq name dictionary)) loop-stack))
                       (error "Set: Not a variable"))
                   (error "Set: Variable not defined"))))

            ;; Пользовательские функции и переменные
            ((assoc word dictionary)
             (let ((entry (assoc word dictionary)))
               (cond
                 ((eq? (cadr entry) 'func)
                  (execute words (caddr entry) stack
                           (cons (+ idx 1) return-stack) dictionary loop-stack))
                 ((eq? (cadr entry) 'var)
                  (execute words (+ idx 1) (cons (caddr entry) stack)
                           return-stack dictionary loop-stack))
                 (else (error "Unknown dictionary entry type")))))

            ;; Неизвестное слово
            (else (error "Unknown word" word))))))

  ;; Вспомогательные функции
  (define (execute-binop words idx stack return-stack dictionary loop-stack op)
    (if (< (length stack) 2)
        (error "Not enough values on stack")
        (execute words (+ idx 1)
                 (cons (op (cadr stack) (car stack)) (cddr stack))
                 return-stack dictionary loop-stack)))
  (define (execute-binop-checked words idx stack return-stack dictionary loop-stack op)
    (if (< (length stack) 2)
        (error "Not enough values on stack")
        (if (= (car stack) 0)
            (error "Division by zero")
            (execute-binop words idx stack return-stack dictionary loop-stack op))))
  (define (execute-unop words idx stack return-stack dictionary loop-stack op)
    (if (null? stack)
        (error "Stack underflow")
        (execute words (+ idx 1)
                 (cons (op (car stack)) (cdr stack))
                 return-stack dictionary loop-stack)))
  (define (execute-stack-op words idx stack return-stack dictionary loop-stack op)
    (if (null? stack)
        (error "Stack underflow")
        (execute words (+ idx 1)
                 (op stack)
                 return-stack dictionary loop-stack)))

  ;; Функция для поиска соответствующего окончания цикла
  (define (find-matching end-word idx words)
    (let ((start-word (vector-ref words idx)))
      (let loop ((i (+ idx 1)) (depth 1))
        (if (>= i (vector-length words))
            (error "No matching end for loop")
            (let ((w (vector-ref words i)))
              (cond
                ((eq? w start-word)
                 (loop (+ i 1) (+ depth 1)))
                ((eq? w end-word)
                 (if (= depth 1)
                     i
                     (loop (+ i 1) (- depth 1))))
                (else (loop (+ i 1) depth))))))))

  ;; Функция для удаления ассоциации по ключу
  (define (remove-assq key alist)
    (cond
      ((null? alist) '())
      ((eq? (caar alist) key) (cdr alist))
      (else (cons (car alist) (remove-assq key (cdr alist))))))

  ;; Начало выполнения
  (execute program 0 stack '() '() '()))


;; testing...

; arithmetic
(interpret #(2 3 +) '()) ; -> (5)
(interpret #(10 4 -) '()) ; -> (6)
(interpret #(3 7 *) '()) ; -> (21)
(interpret #(20 5 /) '()) ; -> (4)
(interpret #(17 5 mod) '()) ; -> (2)
(interpret #(7 neg) '()) ; -> (-7)

; logic
(interpret #(5 5 =) '()) ; -> (-1) 
(interpret #(10 5 >) '()) ; -> (-1) 
(interpret #(3 8 <) '()) ; -> (-1) 
(interpret #(0 not) '()) ; -> (-1) 
(interpret #(-1 0 and) '()) ; -> (0) 
(interpret #(-1 -1 or) '()) ; -> (-1) 

; stack
(interpret #(drop) '(42)) ; -> () 
(interpret #(swap) '(2 3)) ; -> (3 2) 
(interpret #(dup) '(9)) ; -> (9 9) 
(interpret #(over) '(1 2)) ; -> (2 1 2)
(interpret #(rot) '(1 2 3)) ; -> (3 2 1) 
(interpret #(depth) '(1 1 1)) ; -> (3 1 1 1)

; global
(interpret #(   define abs
                    dup 0 <
                    if neg endif
                end
                 9 abs
                -9 abs      ) (quote ()))
;  ⇒ (9 9)

(interpret #(   define =0? dup 0 = end
                define <0? dup 0 < end
                define signum
                    =0? if exit endif
                    <0? if drop -1 exit endif
                    drop
                    1
                end
                 0 signum
                -5 signum
                10 signum       ) (quote ()))
;  ⇒ (1 -1 0)


(interpret #(   define -- 1 - end
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
                4 factorial     ) (quote ()))
;  ⇒ (24 6 2 1 1)

(interpret #(   define =0? dup 0 = end
                define =1? dup 1 = end
                define -- 1 - end
                define fib
                    =0? if drop 0 exit endif
                    =1? if drop 1 exit endif
                    -- dup
                    -- fib
                    swap fib
                    +
                end
                define make-fib
                    dup 0 < if drop exit endif
                    dup fib
                    swap --
                    make-fib
                end
                10 make-fib     ) (quote ()))
;  ⇒ (0 1 1 2 3 5 8 13 21 34 55)

(interpret #(   define =0? dup 0 = end
                define gcd
                    =0? if drop exit endif
                    swap over mod
                    gcd
                end
                90 99 gcd
                234 8100 gcd    ) '())
;  ⇒ (18 9)
(define (run-tests)
  (define tests
    (list
     ;; Test while/wend
     (lambda ()
       (let ((result (interpret #(while wend) '(3 7 4 0 5 9))))
         (equal? result '(5 9))))

     (lambda ()
       (let ((result (interpret #(define sum
                                    dup
                                    while + swap dup wend
                                    drop
                                  end
                                  1 2 3 0 4 5 6 sum)
                                 '())))
         (equal? result '(15 3 2 1))))

     ;; Test break/continue

     


     ))

  ;; Run all tests
  (for-each (lambda (test)
              (if (test)
                  (display "Test passed!\n")
                  (display "Test failed!\n")))
            tests))
(run-tests)

; Тесты для функции interpret

(display (interpret #() '())) ; ⇒ '()
(newline)

(display (interpret #(1 2 3) '(7 8 9))) ; ⇒ '(3 2 1 7 8 9)
(newline)

(display (interpret #(+) '(5 7))) ; ⇒ '(12)
(newline)

(display (interpret #(-) '(4 14))) ; ⇒ '(10)
(newline)

(display (interpret #(*) '(21 2))) ; ⇒ '(42)
(newline)

(display (interpret #(/) '(7 42))) ; ⇒ '(6)
(newline)

(display (interpret #(mod) '(7 40))) ; ⇒ '(5)
(newline)

(display (interpret #(neg) '(77))) ; ⇒ '(-77)
(newline)

(display (interpret #(=) '(13 32))) ; ⇒ '(0)
(newline)

(display (interpret #(=) '(11 11))) ; ⇒ '(-1)
(newline)

(display (interpret #(>) '(13 32))) ; ⇒ '(-1)
(newline)

(display (interpret #(>) '(11 11))) ; ⇒ '(0)
(newline)

(display (interpret #(>) '(32 13))) ; ⇒ '(0)
(newline)

(display (interpret #(<) '(13 32))) ; ⇒ '(0)
(newline)

(display (interpret #(<) '(11 11))) ; ⇒ '(0)
(newline)

(display (interpret #(<) '(32 13))) ; ⇒ '(-1)
(newline)

(display (interpret #(not) '(0))) ; ⇒ '(-1)
(newline)

(display (interpret #(not) '(-1))) ; ⇒ '(0)
(newline)

(display (interpret #(not) '(77))) ; ⇒ '(0)
(newline)

(display (interpret #(and) '(-1 -1))) ; ⇒ '(-1)
(newline)

(display (interpret #(and) '(12 34))) ; ⇒ '(-1)
(newline)

(display (interpret #(and) '(12 0))) ; ⇒ '(0)
(newline)

(display (interpret #(and) '(0 34))) ; ⇒ '(0)
(newline)

(display (interpret #(and) '(0 0))) ; ⇒ '(0)
(newline)

(display (interpret #(or) '(-1 -1))) ; ⇒ '(-1)
(newline)

(display (interpret #(or) '(12 34))) ; ⇒ '(-1)
(newline)

(display (interpret #(or) '(12 0))) ; ⇒ '(-1)
(newline)

(display (interpret #(or) '(0 34))) ; ⇒ '(-1)
(newline)

(display (interpret #(or) '(0 0))) ; ⇒ '(0)
(newline)

(display (interpret #(drop) '(2 3 5 7 11))) ; ⇒ '(3 5 7 11)
(newline)

(display (interpret #(swap) '(2 3 5 7 11))) ; ⇒ '(3 2 5 7 11)
(newline)

(display (interpret #(dup) '(2 3 5 7 11))) ; ⇒ '(2 2 3 5 7 11)
(newline)

(display (interpret #(over) '(2 3 5 7 11))) ; ⇒ '(3 2 3 5 7 11)
(newline)

(display (interpret #(rot) '(2 3 5 7 11))) ; ⇒ '(5 3 2 7 11)
(newline)

(display (interpret #(depth) '(2 3 5 7 11))) ; ⇒ '(5 2 3 5 7 11)
(newline)

(display (interpret #(depth) '())) ; ⇒ '(0)
(newline)

; define не вызывается
(display (interpret #(define zerodiv 1 0 / end) '())) ; ⇒ '()
(newline)

(display (interpret #(define square dup * end square) '(11))) ; ⇒ '(121)
(newline)

(display (interpret #(define x 1 2 exit 3 4 end x) '())) ; ⇒ '(2 1)
(newline)

(display (interpret #(if 1 2 3 endif 4 5 6) '(0))) ; ⇒ '(6 5 4)
(newline)

(display (interpret #(if 1 2 3 endif 4 5 6) '(-1))) ; ⇒ '(6 5 4 3 2 1)
(newline)

(display (interpret #(if 1 2 3 endif 4 5 6) '(77))) ; ⇒ '(6 5 4 3 2 1)
(newline)

(display (interpret
          #(define abs
               dup 0 <
               if neg endif
             end
             abs)
          '(-9))) ; ⇒ '(9)
(newline)

(display (interpret
          #(define -- 1 - end
             5 -- --)
          '())) ; ⇒ '(3)
(newline)

(display (interpret #(2 3 * 4 5 * +) '())) ; ⇒ '(26)
(newline)

(display (interpret
          #(define abs
               dup 0 <
               if neg endif
             end
              9 abs
             -9 abs)
          '())) ; ⇒ '(9 9)
(newline)

(display (interpret
          #(define =0? dup 0 = end
             define <0? dup 0 < end
             define signum
                 =0? if exit endif
                 <0? if drop -1 exit endif
                 drop
                 1
             end
              0 signum
             -5 signum
             10 signum)
          '())) ; ⇒ '(1 -1 0)
(newline)

(display (interpret
          #(define -- 1 - end
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
             4 factorial)
          '())) ; ⇒ '(24 6 2 1 1)
(newline)

(display (interpret
          #(define =0? dup 0 = end
             define =1? dup 1 = end
             define -- 1 - end
             define fib
                 =0? if drop 0 exit endif
                 =1? if drop 1 exit endif
                 -- dup
                 -- fib
                 swap fib
                 +
             end
             define make-fib
                 dup 0 < if drop exit endif
                 dup fib
                 swap --
                 make-fib
             end
             10 make-fib)
          '())) ; ⇒ '(0 1 1 2 3 5 8 13 21 34 55)
(newline)

(display (interpret
          #(define =0? dup 0 = end
             define gcd
                 =0? if drop exit endif
                 swap over mod
                 gcd
             end
             90 99 gcd
             234 8100 gcd)
          '())) ; ⇒ '(18 9)
(newline)



