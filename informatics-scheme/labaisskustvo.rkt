(define (interpret program stack)
  (define (execute words idx stack)
    (if (>= idx (vector-length words))
        stack
        (let ((word (vector-ref words idx)))
          (cond
            ((integer? word) (execute words (+ idx 1) (cons word stack)))

            ; арифметические операции
            ((eq? word '+) (cond ((< (length stack) 2) stack) 
                                (else (execute words (+ idx 1) (cons (+ (cadr stack) (car stack)) (cddr stack))))))
            ((eq? word '-) (cond ((< (length stack) 2) stack)
                                (else (execute words (+ idx 1) (cons (- (cadr stack) (car stack)) (cddr stack))))))
            ((eq? word '*) (cond ((< (length stack) 2) stack)
                                (else (execute words (+ idx 1) (cons (* (cadr stack) (car stack)) (cddr stack))))))
            ((eq? word '/) (cond ((< (length stack) 2) stack)
                                 ((= (car stack) 0) #f) 
                                 (else (execute words (+ idx 1) (cons (quotient (cadr stack) (car stack)) (cddr stack))))))
            ((eq? word 'mod) (cond ((< (length stack) 2) stack)
                                  ((= (car stack) 0) #f) 
                                  (else (execute words (+ idx 1) (cons (modulo (cadr stack) (car stack)) (cddr stack))))))
            ((eq? word 'neg) (cond ((< (length stack) 1) stack)
                                   (else (execute words (+ idx 1) (cons (- (car stack)) (cdr stack))))))

            ; логические операции
            ((eq? word '=) (cond ((< (length stack) 2) stack)
                                (else (execute words (+ idx 1) (cons (if (= (cadr stack) (car stack)) -1 0) (cddr stack))))))
            ((eq? word '<) (cond ((< (length stack) 2) stack)
                                (else (execute words (+ idx 1) (cons (if (< (cadr stack) (car stack)) -1 0) (cddr stack))))))
            ((eq? word '> ) (cond ((< (length stack) 2) stack)
                                 (else (execute words (+ idx 1) (cons (if (> (cadr stack) (car stack)) -1 0) (cddr stack))))))
            ((eq? word 'not) (cond ((< (length stack) 1) stack)
                                  (else (execute words (+ idx 1) (cons (if (zero? (car stack)) -1 0) (cdr stack))))))
            ((eq? word 'and) (cond ((< (length stack) 2) stack)
                                  (else (execute words (+ idx 1)
                                                   (cons (if (and (not (zero? (cadr stack))) (not (zero? (car stack)))) -1 0) (cddr stack))))))
            ((eq? word 'or) (cond ((< (length stack) 2) stack)
                                 (else (execute words (+ idx 1)
                                                  (cons (if (or (not (zero? (cadr stack))) (not (zero? (car stack)))) -1 0) (cddr stack))))))

            ; стековые операции
            ((eq? word 'drop) (cond ((null? stack) stack)
                                   (else (execute words (+ idx 1) (cdr stack)))))
            ((eq? word 'swap) (cond ((or (null? stack) (null? (cdr stack))) stack)
                                   (else (execute words (+ idx 1) (cons (cadr stack) (cons (car stack) (cddr stack)))))))
            ((eq? word 'dup) (cond ((null? stack) stack)
                                  (else (execute words (+ idx 1) (cons (car stack) stack)))))
            ((eq? word 'over) (cond ((or (null? stack) (null? (cdr stack))) stack)
                                   (else (execute words (+ idx 1) (cons (cadr stack) stack)))))
            ((eq? word 'rot) (cond ((or (null? stack) (null? (cdr stack)) (null? (cddr stack))) stack)
                                  (else (execute words (+ idx 1)
                                                      (cons (caddr stack) (cons (cadr stack) (cons (car stack) (cdddr stack))))))))
            ((eq? word 'depth) (execute words (+ idx 1) (cons (length stack) stack)))

            ;; управляющие конструкции
            ((eq? word 'define)
             (let ((name (vector-ref words (+ idx 1))))
               (let loop ((i (+ idx 2)))
                 (if (or (>= i (vector-length words)) (eq? (vector-ref words i) 'end))
                     (execute words (+ i 1) stack return-stack (cons (cons name (+ idx 2)) dictionary))
                     (loop (+ i 1))))))
            ((eq? word 'end)
             (if (null? return-stack)
                 stack
                 (execute words (car return-stack) stack (cdr return-stack) dictionary)))
            ((eq? word 'exit)
             (if (null? return-stack)
                 stack
                 (execute words (car return-stack) stack (cdr return-stack) dictionary)))
            ((eq? word 'if)
             (if (zero? (car stack))
                 (let loop ((i (+ idx 1)))
                   (if (or (>= i (vector-length words)) (eq? (vector-ref words i) 'endif))
                       (execute words (+ i 1) (cdr stack) return-stack dictionary)
                       (loop (+ i 1))))
                 (execute words (+ idx 1) (cdr stack) return-stack dictionary)))
            ((eq? word 'endif) (execute words (+ idx 1) stack return-stack dictionary))

            ;; пользовательские функции
            ((assoc word dictionary)
             (execute words (cdr (assoc word dictionary)) stack (cons (+ idx 1) return-stack) dictionary))

            ;; unknown 
            (else stack)))))

  (execute program 0 stack))


;; testing...

; арифметические операции
(interpret #(2 3 +) '()) ; -> (5)
(interpret #(10 4 -) '()) ; -> (6)
(interpret #(3 7 *) '()) ; -> (21)
(interpret #(20 5 /) '()) ; -> (4)
(interpret #(17 5 mod) '()) ; -> (2)
(interpret #(7 neg) '()) ; -> (-7)

; логические операции
(interpret #(5 5 =) '()) ; -> (-1) 
(interpret #(10 5 >) '()) ; -> (-1) 
(interpret #(3 8 <) '()) ; -> (-1) 
(interpret #(0 not) '()) ; -> (-1) 
(interpret #(-1 0 and) '()) ; -> (0) 
(interpret #(-1 -1 or) '()) ; -> (-1) 

; стековые операции
(interpret #(drop) '(42)) ; -> () 
(interpret #(swap) '(2 3)) ; -> (3 2) 
(interpret #(dup) '(9)) ; -> (9 9) 
(interpret #(over) '(1 2)) ; -> (2 1 2)
(interpret #(rot) '(1 2 3)) ; -> (3 2 1) 
(interpret #(depth) '(1 1 1)) ; -> (3 1 1 1)

