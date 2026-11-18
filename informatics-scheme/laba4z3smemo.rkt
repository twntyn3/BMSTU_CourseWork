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
(display(tribonacci-memo 30))
(time tribonacci-memo 30)
