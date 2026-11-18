(load "hw4-read-words.scm")
(load "unit-test.scm")
(load "expected-output.scm")


(display "\n-=РОБОТ-ПРОВЕРЯЛЬЩИК ВЫПОЛНЯЕТ ТЕСТЫ ДЛЯ (read-words)=-\n\n")


(define read-words-test (test (read-words) expected-output))


(define **test-succeed-803** (run-test read-words-test))
