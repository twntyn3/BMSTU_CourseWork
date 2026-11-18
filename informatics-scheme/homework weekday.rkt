
#|(define (srez a b)
  (quotient a b))
(define (mod a b)
  (- a (* b (quotient a b))))
|#
#|
(define (day-of-week day mes9c god)
  (let* ((nm (if (<= mes9c 2) (+ mes9c 12) mes9c))
         (ny (if (<= mes9c 2) (- god 1) god))
         (J (srez ny 100))
         (K (mod ny 100))
         (h (mod (+ day
                    (srez (* 13 (+ nm 1)) 5)
                    K
                    (srez K 4)
                    (srez J 4)
                    (- (* J 2)))
                 7))
         )
    (- h 1)))
|#




#|(define (linear-equation a11 a12 a21 a22 b1 b2)
  (let ((D (- (* a11 a22) (* a12 a21)))
        (DX (- (* b1 a22) (* b2 a12)))
        (DY (- (* a11 b2) (* a21 b1))))
    (cond ((and (= D 0) (= DX 0) (= DY 0)) '())  
          ((= D 0) '())                         
          (else (list (/ DX D) (/ DY D))))))
|#


(define (my-gcd a b)
  (if (> (abs a) (abs b))
      (if (= b 0)
          a
          (my-gcd (abs b) (- a (* b (quotient a b)))))
      (if (= a 0)
          b
          (my-gcd (abs a) (- b (* a (quotient b a))))
          )))
(define (my-lcm a b)
  (if (or (= a 0) (= b 0))
      0  
      (quotient (* (abs a) (abs b)) (my-gcd a b))))

(define (prime? n)
  (define (is-div? n d)
    (= (- n (* d (quotient n d))) 0))
  (define (4ek-div n d)
    (if (> d (sqrt n))
        #t
        (if (is-div? n d)
            #f
            (4ek-div n (+ d 1)))))
  (if (< n 2)
      #f
      (4ek-div n 2)))


  
  
  
    

  
 

