(load "homework5.scm")
(load "unit-test.scm")


(display "\n-=РОБОТ-ПРОВЕРЯЛЬЩИК ВЫПОЛНЯЕТ ТЕСТЫ ДЛЯ ИНТЕРПРЕТАТОР=-\n\n")


(define tests
  (list (test (interpret #() '()) '())
        (test (interpret #(1 2 3) '(7 8 9)) '(3 2 1 7 8 9))
        (test (interpret #(+) '(5 7)) '(12))
        (test (interpret #(-) '(4 14)) '(10))
        (test (interpret #(*) '(21 2)) '(42))
        (test (interpret #(/) '(7 42)) '(6))
        (test (interpret #(mod) '(7 40)) '(5))
        (test (interpret #(neg) '(77)) '(-77))
        (test (interpret #(=) '(13 32)) '(0))
        (test (interpret #(=) '(11 11)) '(-1))
        (test (interpret #(>) '(13 32)) '(-1))
        (test (interpret #(>) '(11 11)) '(0))
        (test (interpret #(>) '(32 13)) '(0))
        (test (interpret #(<) '(13 32)) '(0))
        (test (interpret #(<) '(11 11)) '(0))
        (test (interpret #(<) '(32 13)) '(-1))
        (test (interpret #(not) '(0)) '(-1))
        (test (interpret #(not) '(-1)) '(0))
        (test (interpret #(not) '(77)) '(0))
        (test (interpret #(and) '(-1 -1)) '(-1))
        (test (interpret #(and) '(12 34)) '(-1))
        (test (interpret #(and) '(12 0)) '(0))
        (test (interpret #(and) '(0 34)) '(0))
        (test (interpret #(and) '(0 0)) '(0))
        (test (interpret #(or) '(-1 -1)) '(-1))
        (test (interpret #(or) '(12 34)) '(-1))
        (test (interpret #(or) '(12 0)) '(-1))
        (test (interpret #(or) '(0 34)) '(-1))
        (test (interpret #(or) '(0 0)) '(0))
        (test (interpret #(drop) '(2 3 5 7 11)) '(3 5 7 11))
        (test (interpret #(swap) '(2 3 5 7 11)) '(3 2 5 7 11))
        (test (interpret #(dup) '(2 3 5 7 11)) '(2 2 3 5 7 11))
        (test (interpret #(over) '(2 3 5 7 11)) '(3 2 3 5 7 11))
        (test (interpret #(rot) '(2 3 5 7 11)) '(5 3 2 7 11))
        (test (interpret #(depth) '(2 3 5 7 11)) '(5 2 3 5 7 11))
        (test (interpret #(depth) '()) '(0))
        (test (interpret #(define zerodiv 1 0 / end) '()) '()) ;; не вызывается
        (test (interpret #(define square dup * end square) '(11)) '(121))
        (test (interpret #(define x 1 2 exit 3 4 end x) '()) '(2 1))
        (test (interpret #(if 1 2 3 endif 4 5 6) '(0)) '(6 5 4))
        (test (interpret #(if 1 2 3 endif 4 5 6) '(-1)) '(6 5 4 3 2 1))
        (test (interpret #(if 1 2 3 endif 4 5 6) '(77)) '(6 5 4 3 2 1))

        (test (interpret #(define abs
                               dup 0 <
                               if neg endif
                           end
                           abs)
                         '(-9))
              '(9))

        (test (interpret #(define -- 1 - end
                           5 -- --)
                         '())
              '(3))

        (test (interpret #(2 3 * 4 5 * +) '()) '(26))

        (test (interpret #(define abs
                               dup 0 <
                               if neg endif
                           end
                            9 abs
                           -9 abs)
                         '())
              '(9 9))

        (test (interpret #(define =0? dup 0 = end
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
                         '())
              '(1 -1 0))

        (test (interpret #(define -- 1 - end
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
                         '())
              '(24 6 2 1 1))

        (test (interpret #(define =0? dup 0 = end
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
                         '())
              '(0 1 1 2 3 5 8 13 21 34 55))

        (test (interpret #(define =0? dup 0 = end
                           define gcd
                               =0? if drop exit endif
                               swap over mod
                               gcd
                           end
                           90 99 gcd
                           234 8100 gcd)
                         '())
              '(18 9))))


(define **test-succeed-13828** (run-tests tests))
