(load "homework6.scm")
(load "unit-test.scm")


(display "\n-=РОБОТ-ПРОВЕРЯЛЬЩИК ВЫПОЛНЯЕТ ТЕСТЫ ДЛЯ ТОКЕНИЗАТОРА=-\n\n")


(define tests
  (list (test (tokenize "1") '(1))
        (test (tokenize "-a") '(- a))
        (test (tokenize "-a + b * x^2 + dy") '(- a + b * x ^ 2 + dy))
        (test (tokenize "(a - 12)/(b + 34)") '("(" a - 12 ")" / "(" b + 34 ")"))
        (test (tokenize "  - a+b*x ^ 2+dy  ") '(- a + b * x ^ 2 + dy))
        (test (tokenize "  (a-1)/(b+1)   ") '("(" a - 1 ")" / "(" b + 1 ")"))
        ;; числа с плавающей запятой есть в условии задачи
        (test (tokenize "6.022e23 * 1.38e-23 is r") '(6.022e23 * 1.38e-23 is R))
        (test (tokenize "1.2.3") #f)
        (test (tokenize "1e2e3") #f)
        (test (tokenize "1e2.3") #f)

        (test (tokenize "!@#$%^&*()") #f)
        (test (tokenize "12x34 56y78") #f)
        (test (tokenize "12y34 56y78") #f)
        (test (tokenize "            ") '())))


(define **test-succeed-10168** (run-tests tests))
