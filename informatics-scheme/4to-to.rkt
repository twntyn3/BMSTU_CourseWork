(define (derivative expr)
  (cond
    ((number? expr) 0)
    ((eq? expr 'x) 1)

    ;; Минус
    ((and (pair? expr) (equal? (car expr) '-) (= (length (cdr expr)) 1))
     (list '- (derivative (cadr expr))))

    ;; Вычитание
    ((and (pair? expr) (eq? (car expr) '-))
     (cons '- (map derivative (cdr expr))))

    ;; Сложение
    ((and (pair? expr) (eq? (car expr) '+))
     (cons '+ (map derivative (cdr expr))))

    ;; Умножение 
    ((and (pair? expr) (eq? (car expr) '*))
     (let ((terms (cdr expr)))
       (if (= (length terms) 2)
           (let ((u (car terms)) (v (cadr terms)))
             (list '+
                   (list '* (derivative u) v)
                   (list '* u (derivative v))))
           (let ((u (car terms))
                 (rest (cons '* (cdr terms))))
             (list '+
                   (list '* (derivative u) rest)
                   (list '* u (derivative rest)))))))

    ;; Деление
    ((and (pair? expr) (eq? (car expr) '/))
     (let ((u (cadr expr)) (v (caddr expr)))
       (list '/
             (list '-
                   (list '* (derivative u) v)
                   (list '* u (derivative v)))
             (list '* v v))))

    ;; Степенная
    ((and (pair? expr) (eq? (car expr) 'expt))
     (let ((base (cadr expr)) (exp (caddr expr)))
       (if (number? exp)
           (list '* exp (list 'expt base (- exp 1)))
           (list '* (list '* exp (list 'log base))
                 (list 'expt base exp)))))

    ;; Логарифм
    ((and (pair? expr) (eq? (car expr) 'log))
     (let ((u (cadr expr)))
       (list '/ (derivative u) u)))

    ;; Экспонента
    ((and (pair? expr) (eq? (car expr) 'exp))
     (let ((u (cadr expr)))
       (list '* (derivative u) (list 'exp u))))

    ;; Синус
    ((and (pair? expr) (eq? (car expr) 'sin))
     (let ((u (cadr expr)))
       (list '* (derivative u) (list 'cos u))))

    ;; Косинус
    ((and (pair? expr) (eq? (car expr) 'cos))
     (let ((u (cadr expr)))
       (list '* -1 (list '* (derivative u) (list 'sin u)))))

    (else (error "к такому я не был готов" expr))))
