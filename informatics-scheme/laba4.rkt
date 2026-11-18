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


(display (map 1/x '(-2 -1 0 1 2)))
;;numer 2.1
(define (select-rec source dest)
  (define (recursive? proc-name body)
    (if (not (pair? body))
        #f
        (or (equal? proc-name (car body))
            (recursive? proc-name (cdr body)))))
  
  (define (find-recursive-procs lines)
    (define (helper lines rec-procs)
      (cond
        ((null? lines) rec-procs)
        ((string-prefix? "(define " (car lines))
         (let* ((proc-name (second (read (open-input-string (car lines)))))
                (body (third (read (open-input-string (car lines))))))
           (if (recursive? proc-name body)
               (helper (cdr lines) (cons (car lines) rec-procs))
               (helper (cdr lines) rec-procs)))
         )
        (else (helper (cdr lines) rec-procs))))
    
    (helper lines '()))
  
  (define (write-procs to-write)
    (define out (open-output-file dest))
    (for-each (lambda (proc) (display proc out) (newline out)) to-write)
    (close-output-port out))
  
  (let ((lines (port->lines (open-input-file source))))
    (write-procs (find-recursive-procs lines))))


(define (port->lines port)
  (let loop ((line (read-line port 'eof)) (lines '()))
    (cond
      ((eq? line 'eof) (reverse lines))
      (else (loop (read-line port 'eof) (cons line lines))))))

;; primer
;; (select-rec "text1.scm" "text2.scm")

;;numer 2.2
(define (text-stat source)
  (define (word? w)
    (and (not (null? w))
         (string->number w)))
  
  (define (number? w)
    (string->number w))

  (define (formula? w)
    (or (string-match? "[a-zA-Z]" w)
        (string-match? "[0-9]" w)))

  (define (analyze-line line)
    (define words (string-split line))
    (define word-count (count (lambda (w) (and (word? w) (not (number? w)))) words))
    (define number-count (count number? words))
    (define formula-count (count formula? words))
    (values word-count number-count formula-count))
  
  (define (count-statistics lines)
    (define (helper lines stats)
      (if (null? lines)
          stats
          (let-values (((w n f) (analyze-line (car lines))))
            (helper (cdr lines) (list (+ (car stats) w)
                                      (+ (cadr stats) n)
                                      (+ (caddr stats) f))))))
    (helper lines '(0 0 0)))

  (define (read-lines port)
    (let loop ((line (read-line port 'eof)) (lines '()))
      (cond
        ((eq? line 'eof) (reverse lines))
        (else (loop (read-line port 'eof) (cons line lines))))))

  (define (print-statistics stats)
    (display "Words: ")
    (display (car stats))
    (newline)
    (display "Numers: ")
    (display (cadr stats))
    (newline)
    (display "Formulbl: ")
    (display (caddr stats))
    (newline))

  (let ((lines (read-lines (open-input-file source))))
    (print-statistics (count-statistics lines))))

;; Example 
;;(text-stat "textik.txt")


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



;zadanie numer 4
;;;;;;;;;;;;;;;;


(define-syntax lazy-cons
  (syntax-rules ()
    ((_ a b)
     (cons a (delay b)))))  


(define (lazy-car p)
  (car p))  


(define (lazy-cdr p)
  (force (cdr p)))  
;; Функция для получения первых k элементов ленивого списка
(define (lazy-head xs k)
  (if (zero? k)
      '()  ; Возвращаем пустой список, если k = 0
      (cons (lazy-car xs) (lazy-head (lazy-cdr xs) (- k 1)))))  ; Составляем новый список из первых k элементов

;; Функция для получения k-го элемента ленивого списка
(define (lazy-ref xs k)
  (if (zero? k)
      (lazy-car xs)  ; Если k = 0, возвращаем первый элемент
      (lazy-ref (lazy-cdr xs) (- k 1))))  ; Иначе, продолжаем поиск в хвосте списка

;; Функция для применения процедуры к каждому элементу ленивого списка
(define (lazy-map proc xs)
  (if (null? xs)  ; Если список пуст, возвращаем пустой список
      '()
      (lazy-cons (proc (lazy-car xs)) (lazy-map proc (lazy-cdr xs)))))  ; Применяем proc и продолжаем с хвостом

;; Функция для "ленивого" слияния двух списков
(define (lazy-zip xs ys)
  (if (or (null? xs) (null? ys))  ; Если один из списков пуст, возвращаем пустой список
      '()
      (lazy-cons (list (lazy-car xs) (lazy-car ys))  ; Создаём список из текущих элементов
                 (lazy-zip (lazy-cdr xs) (lazy-cdr ys)))))  ; Рекурсивно продолжаем с хвостами

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
                         (lazy-zip (naturals 1) factorials))))  ; Объединяем с натуральными

;ehample
(display (lazy-head factorials 12)) 
(newline)




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
;;c
(define << " ")
; Определяем переменную endl для обозначения перехода на новую строку
(define endl 'endl)

; Определяем процедуру cout, которая принимает любое количество аргументов
(define (cout . args)
  ; Обходим все аргументы и выводим их с помощью print-helper
  (for-each print-helper args))

; Вспомогательная процедура для вывода каждого элемента
(define (print-helper elem)
  ; Проверяем, является ли элемент 'endl
  (if (eq? elem endl)
      ; Если это 'endl, выполняем переход на новую строку
      (newline)
      ; Иначе выводим элемент как строку
      (display elem)))

; Пример использования cout, передавая все аргументы одним списком
(cout << "a = " << 1 << endl << "b = " << 2 << endl)


(cout << "Первые 12 факториалов:" << endl)
(display (lazy-head factorials 12)) 




