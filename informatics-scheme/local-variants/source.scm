(define (factorial n)
  (if (= n 0)
      1
      (* n (factorial (- n 1)))))

(define (sum a b)
  (+ a b))

(define (fibonacci n)
  (if (<= n 1)
      n
      (+ (fibonacci (- n 1)) (fibonacci (- n 2)))))

(define (square x)
  (* x x))
