(load "2024-ib/lists.scm")
(load "unit-test.scm")


(display "\n-=РОБОТ-ПРОВЕРЯЛЬЩИК ВЫПОЛНЯЕТ ТЕСТЫ ДЛЯ hw2-lists=-\n\n")


(define tests
  (list (test (my-range  0 11 3) '(0 3 6 9))
        (test (my-flatten '((1) 2 (3 (4 5)) 6)) '(1 2 3 4 5 6))
        (test (my-flatten '(1 2 (3 (4 5)) 6)) '(1 2 3 4 5 6))
        (test (my-element? 1 '(3 2 1)) #t)
        (test (my-element? 4 '(3 2 1)) #f)
        (test (my-filter odd? (my-range 0 10 1)) '(1 3 5 7 9))
        (test (my-filter (lambda (x) (= (remainder x 3) 0)) (my-range 0 13 1))
              '(0 3 6 9 12))
        (test (my-fold-left  quotient '(16 2 2 2 2))   1)
        (test (my-fold-left  quotient '(1))            1)
        (test (my-fold-right expt     '(2 3 4))        2417851639229258349412352)
        (test (my-fold-right expt     '(2))            2)
        (test (my-fold-left  append   '((a b) (c d)))  '(a b c d))
        (test (my-fold-right append   '((a b) (c d)))  '(a b c d))
        (test (reverse! '(a b c d e)) '(e d c b a))
        (test (reverse! '()) '())
        (test (append! '() '(a b) '() '(c d) '(e f)) '(a b c d e f))
        (test (append! '() '(a b) '() '(c d) '(e f) '()) '(a b c d e f))
        (test (append! '() '() '()) '())
        (test (append!) '())
        (test (let* ((xs '(1 2 3))
                     (ys '(4 5 6))
                     (zs (append! xs ys)))
                (set-car! xs 'a)
                (set-car! ys 'b)
                zs)
              '(a 2 3 b 5 6))))


(define **test-succeed-29130** (run-tests tests))
