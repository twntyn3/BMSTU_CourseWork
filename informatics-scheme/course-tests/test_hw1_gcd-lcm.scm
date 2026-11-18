(load "hw1-gcd-lcm.scm")
(load "unit-test.scm")


(display "\n-=РОБОТ-ПРОВЕРЯЛЬЩИК ВЫПОЛНЯЕТ ТЕСТЫ ДЛЯ gcd-lcm=-\n\n")


(define tests
  (list (test (my-gcd 3542 2464) 154)
        (test (my-gcd -3542 2464) 154)
        (test (my-gcd -3542 -2464) 154)
        (test (my-gcd 3542 -2464) 154)
        (test (my-lcm 3 4) 12)
        (test (prime? 11) #t)
        (test (prime? 12) #f)))


(define **test-succeed-28365** (run-tests tests))
