(load "2024-ib/derivative.scm")
(load "unit-test.scm")

(define ie (interaction-environment))

(define-syntax derivative-test
  (syntax-rules ()
    ((derivative-test argument expected call-arg)
     (test (round_1e-6 (eval `(let ((x call-arg))
                                ,(derivative 'argument))
                             ie))
           (round_1e-6 (eval '(let ((x call-arg))
                                expected)
                             ie))))))

(define PI (* 4 (atan 1)))

(define (round_1e-6 x)
  (/ (round (* x 1e6)) 1e6))


(display "\n-=РОБОТ-ПРОВЕРЯЛЬЩИК ВЫПОЛНЯЕТ ТЕСТЫ ДЛЯ ПРОИЗВОДНОЙ=-\n\n")


(define tests
  (list (derivative-test 2 0 10.16884)
        (derivative-test x 1 10.16884)
        (derivative-test (- x) -1 10.16884)
        (derivative-test (* 1 x) 1 10.16884)
        (derivative-test (* -1 x) -1 10.16884)
        (derivative-test (* -4 x) -4 10.16884)
        (derivative-test (* x 10) 10 10.16884)
        (derivative-test (- (* 2 x) 3) 2 10.16884)
        (derivative-test (expt x 10) (* 10 (expt x 9)) 10.16884)
        (derivative-test (* 2 (expt x 5)) (* 10 (expt x 4)) 10.16884)
        (derivative-test (expt x -2) (* -2 (expt x -3)) 10.16884)
        (derivative-test (expt 5 x) (* (log 5) (expt 5 x)) 10.16884)
        (derivative-test (cos x) (- (sin x)) (/ PI 2))
        (derivative-test (sin x) (cos x) 0)
        (derivative-test (sin x) (cos x) 0.16884)
        (derivative-test (exp x) (exp x) 10.16884)
        (derivative-test (* 2 (exp x)) (* 2 (exp x)) 10.16884)
        (derivative-test (* 2 (exp (* 2 x))) (* 4 (exp (* 2 x))) 10.16884)
        (derivative-test (log x) (/ 1 x) 7.16884)
        (derivative-test (* (log x) 3) (/ 3 x) 7.16884)
        (derivative-test (+ (expt x 3) (* x x)) (+ (* 3 x x) (* 2 x)) 10.16884)
        (derivative-test (- (* 2 (expt x 3)) (* 2 (expt x 2)))
                         (- (* 6 x x) (* 4 x))
                         10.16884)
        (derivative-test (/ 3 x) (/ -3 (* x x)) 7.16884)
        (derivative-test (/ 3 (* 2 (expt x 2))) (/ -3 (expt x 3)) 7.16884)
        (derivative-test (* 2 (sin x) (cos x))
                         (* 2 (cos (* 2 x)))
                         (/ PI 3))
        (derivative-test (* 2 (exp x) (sin x) (cos x))
                         (* (exp x) (+ (* 2 (cos (* 2 x))) (sin (* 2 x))))
                         0.16884)
        (derivative-test (cos (* 2 (expt x 2)))
                         (* -4 x (sin (* 2 (expt x 2))))
                         5.16884)
        (derivative-test (sin (log (expt x 2)))
                         (/ (* 2 (cos (log (expt x 2)))) x)
                         15.16884)
        (derivative-test (+ (sin (+ x x)) (cos (* x 2 x)))
                         (+ (* 2 (cos (* 2 x))) (* -4 (sin (* x 2 x)) x))
                         10.16884)
        (derivative-test (* (sin (+ x x)) (cos (* x 2 x)))
                         (+ (* (- 1 (* 2 x)) (cos (* 2 x (- 1 x))))
                            (* (+ 1 (* 2 x)) (cos (* 2 x (+ 1 x)))))
                         5.16884)
        (derivative-test (* x x x x)
			 (* 4 x x x)
                         5.16884)))


(define **test-succeed-16884** (run-tests tests))









(display "Testing derivatives...\n")

(display "Test 1: Constant 2\n")
(display (derivative '2)) ; => 0

(display "\nTest 2: Variable x\n")
(display (derivative 'x)) ; => 1

(display "\nTest 3: Negation of x\n")
(display (derivative '(- x))) ; => -1

(display "\nTest 4: Multiplication by 1\n")
(display (derivative '(* 1 x))) ; => 1

(display "\nTest 5: Multiplication by -1\n")
(display (derivative '(* -1 x))) ; => -1

(display "\nTest 6: Multiplication by -4\n")
(display (derivative '(* -4 x))) ; => -4

(display "\nTest 7: Multiplication by 10\n")
(display (derivative '(* x 10))) ; => 10

(display "\nTest 8: Subtraction (- (* 2 x) 3)\n")
(display (derivative '(- (* 2 x) 3))) ; => 2

(display "\nTest 9: Power function (expt x 10)\n")
(display (derivative '(expt x 10))) ; => (* 10 (expt x 9))

(display "\nTest 10: Scaled power function (* 2 (expt x 5))\n")
(display (derivative '(* 2 (expt x 5)))) ; => (* 10 (expt x 4))

(display "\nTest 11: Negative power function (expt x -2)\n")
(display (derivative '(expt x -2))) ; => (* -2 (expt x -3))

(display "\nTest 12: Exponential base (expt 5 x)\n")
(display (derivative '(expt 5 x))) ; => (* (log 5) (expt 5 x))

(display "\nTest 13: Cosine function (cos x)\n")
(display (derivative '(cos x))) ; => (* -1 (sin x))

(display "\nTest 14: Sine function (sin x)\n")
(display (derivative '(sin x))) ; => (cos x)

(display "\nTest 15: Exponential function (exp x)\n")
(display (derivative '(exp x))) ; => (exp x)

(display "\nTest 16: Scaled exponential function (* 2 (exp x))\n")
(display (derivative '(* 2 (exp x)))) ; => (* 2 (exp x))

(display "\nTest 17: Nested exponential (* 2 (exp (* 2 x)))\n")
(display (derivative '(* 2 (exp (* 2 x))))) ; => (* 4 (exp (* 2 x)))

(display "\nTest 18: Logarithm (log x)\n")
(display (derivative '(log x))) ; => (/ 1 x)

(display "\nTest 19: Scaled logarithm (* (log x) 3)\n")
(display (derivative '(* (log x) 3))) ; => (/ 3 x)

(display "\nTest 20: Sum of polynomials (+ (expt x 3) (* x x))\n")
(display (derivative '(+ (expt x 3) (* x x)))) ; => (+ (* 3 x x) (* 2 x))

(display "\nTest 21: Difference of scaled powers (- (* 2 (expt x 3)) (* 2 (expt x 2)))\n")
(display (derivative '(- (* 2 (expt x 3)) (* 2 (expt x 2))))) ; => (- (* 6 x x) (* 4 x))

(display "\nTest 22: Fraction (/ 3 x)\n")
(display (derivative '(/ 3 x))) ; => (/ -3 (expt x 2))

(display "\nTest 23: Nested fraction (/ 3 (* 2 (expt x 2)))\n")
(display (derivative '(/ 3 (* 2 (expt x 2))))) ; => (/ -3 (expt x 3))

(display "\nTest 24: Product of sine and cosine (* 2 (sin x) (cos x))\n")
(display (derivative '(* 2 (sin x) (cos x)))) ; => (* 2 (cos (* 2 x)))

(display "\nTest 25: Mixed trigonometric and exponential (* 2 (exp x) (sin x) (cos x))\n")
(display (derivative '(* 2 (exp x) (sin x) (cos x)))) ; => (* (exp x) (+ (* 2 (cos (* 2 x))) (sin (* 2 x))))

(display "\nTest 26: Nested trigonometric function (cos (* 2 (expt x 2)))\n")
(display (derivative '(cos (* 2 (expt x 2))))) ; => (* -4 x (sin (* 2 (expt x 2))))

(display "\nTest 27: Logarithm and trigonometric composition (sin (log (expt x 2)))\n")
(display (derivative '(sin (log (expt x 2))))) ; => (/ (* 2 (cos (log (expt x 2)))) x)

(display "\nTest 28: Nested sum and product (+ (sin (+ x x)) (cos (* x 2 x)))\n")
(display (derivative '(+ (sin (+ x x)) (cos (* x 2 x))))) ; => (+ (* 2 (cos (* 2 x))) (* -4 (sin (* x 2 x)) x))

(display "\nTest 29: Product of nested trig functions (* (sin (+ x x)) (cos (* x 2 x)))\n")
(display (derivative '(* (sin (+ x x)) (cos (* x 2 x))))) ; Complex result (see problem statement)

(display "\nTest 30: High power product (* x x x x)\n")
(display (derivative '(* x x x x))) ; => (* 4 x x x)

(display "\nAll tests complete.\n")