(define (tribonacci n)
  (cond
    ((= n 0) 0)
    ((= n 1) 0)
    ((= n 2) 1)
    (else (+ (tribonacci (- n 1))
              (tribonacci (- n 2))
              (tribonacci (- n 3))))))
(time (tribonacci 30))