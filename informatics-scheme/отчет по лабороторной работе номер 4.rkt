% Лабораторная работа № 4. Метапрограммирование. Отложенные вычисления
% 28 октября 2024 г.
% Матвей Хромов, ИУ9-11Б

# Цель работы

На примере языка Scheme ознакомиться со средствами метапрограммирования
(«код как данные», макросы) и подходами к оптимизации вычислений (мемоизация
результатов вычислений, отложенные вычисления).

В работе также предлагается разработать дополнительное средство отладки программ —
каркас для отладки с помощью утверждений. На этом примере предлагается ознакомится
с типичным применением программирования с использованием продолжений.



# Индивидуальный вариант
…названия процедур и макросов, которые требуется реализовать…

Утверждение (assertion) — проверка на истинность некоторого условия, заданного
программистом. По традиции осуществляется процедурой (функцией) с именем assert.
Включается в код во время написания кода и отладки с целью установки ограничений
на значения и выявления недопустимых значений. Если в процессе выполнения
программы указанное условие нарушается, то программа завершается с выводом
диагностического сообщения о том, какое условие было нарушено. Если условие
соблюдено, то выполнение программы продолжается, никаких сообщений не выводится.

Реализуйте каркас (фреймворк) для отладки с помощью утверждений. Пусть Ваш каркас
перед использованием инициализируется вызовом (use-assertions), а сами утверждения
записываются в коде ниже в виде (assert условие). Если условие не выполнено,
происходит завершение работы программы без возникновения ошибки выполнения и вывод
в консоль диагностического сообщения вида FAILED: условие.

Реализуйте функцию вычисления n-го “числа трибоначчи”

Реализуйте версию этой функции с мемоизацией результатов вычислений. Сравните время
вычисления значения функций для разных (умеренно больших) значений её аргументов без
мемоизации и с мемоизацией.

Используя средства языка Scheme для отложенных вычислений, реализуйте средства для работы
с бесконечными «ленивыми» точечными парами и списками:

Гигиенический макрос (lazy-cons a b), конструирующий ленивую точечную пару вида
(значение-a . обещание-вычислить-значение-b). Почему макрос в данном случае предпочтительнее
процедуры?
Процедуру (lazy-car p), возвращающую значение 1-го элемента «ленивой» точечной пары p.
Процедуру (lazy-cdr p), возвращающую значение 2-го элемента «ленивой» точечной пары p.
На их основе определите:

Процедуру (lazy-head xs k), возвращающую значение k первых элементов «ленивого» списка xs в
виде списка.
Процедуру (lazy-ref xs k), возвращающую значение k-го элементa «ленивого» списка xs.
Процедуру (lazy-map proc xs), принимающую «ленивый» список xs и формирующую новый «ленивый» список,
полученный применением (proc x) к каждому x из xs.
Процедуру (lazy-zip xs ys), принимающую два «ленивых» списка xs и ys и формирующую новый «ленивый»
список, составленный из списков (list x y) для каждых x и y из xs и ys соответственно. Поведение
(lazy-zip xs ys) эквивалентно (map list xs ys) с тем отличием, что списки «ленивые»

Напишите процедуру (select-rec source dest), которая принимает два параметра: имя исходного файла на
языке Scheme source и имя целевого файла dest, куда следует выписать только рекурсивные процедуры из
первого файла.

Напишите процедуру (text-stat source), которая принимает текстовый файл и подсчитывает в нём количество
слов (состоят из букв, дефисов и апострофов),чисел (состят из цифр) и
формул (состоят из букв, цифр и математических знаков, например, E=mc2 или H2SO4).

Используйте примитивы lazy-cons, lazy-map и lazy-zip

Напишите макросы:

(unless cond? expr1 expr2 … exprn), который выполняет последовательность выражений expr1 expr2 … exprn,
если условие cond? ложно.

Реализуйте макрос while, который позволит организовывать циклы с предусловием

Реализуйте макрос для последовательного вывода значений в стандартный поток вывода вида:

(cout << "a = " << 1 << endl << "b = " << 2 << endl)

# Реализация

```

;number 1

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
;;number 2.2

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

;;number 3 without memo
(define (tribonacci n)
  (cond
    ((= n 0) 0)
    ((= n 1) 0)
    ((= n 2) 1)
    (else (+ (tribonacci (- n 1))
             (tribonacci (- n 2))
             (tribonacci (- n 3))))))
;;number 3 s memo
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

;zadanie 4

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


;; perevod from haskel langauge;
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

;;задание 5
;;a
(define-syntax unless
  (syntax-rules ()
    ((unless cond? expr1 expr2 ...)
     (if (not cond?)
         (begin expr1 expr2 ...)))))
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


```

# Тестирование

```

Welcome to DrRacket, version 8.7 [3m].
Language: R5RS; memory limit: 256 MB.
(1 1/2 1/3 1/4 1/5)
fail (not (zero? x))
(1 1 1 1 1)
(1 1 2 6 24 120 720 5040 40320 362880 3628800 39916800)
#(1 1 1)
 a = 1 
 b = 2 
(1 1 2 6 24 120 720 5040 40320 362880)
15902591
15902591


```

# Вывод

На примере языка Scheme ознакомился со средствами метапрограммирования
(«код как данные», макросы) и подходами к оптимизации вычислений (мемоизация
результатов вычислений, отложенные вычисления).

В работе также разрабрал дополнительное средство отладки программ —
каркас для отладки с помощью утверждений. На этом примере ознакомился
с типичным применением программирования с использованием продолжений.

Узнал о существовании функции member в scheme и столкнулся с тем, что функциб my-even?
мне вообще не требовалось писать. Также сравнивал время в третьем задании, где требуется написать
реализовать функцию вычисления n-го “числа трибоначчи” (последовательности чисел, которой первые
три числа равны соответственно 0, 0 и 1, а каждое последующее число — сумме предыдущих трех чисел
(с мемоизацией и без) с помощью программы gracket, где есть возмжность посмотреть результаты
работы функции time, результатами времени на 30-ый член последовательности без мемоизации -
(cpu time: 127 real time: 129 gc time: 0) и с мемоизацией (cpu time: 0 real time: 0 gc time: 0)
Также мои общие навыки программирования на языке scheme серьезно повысились во время реализации
функциий в этой лабораторной работе.


