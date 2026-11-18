(define (read-words)
  (define (skip-spaces)
    (let ((c (peek-char)))
      (if (and (not (eof-object? c)) (char-whitespace? c))
          (begin (read-char) (skip-spaces))
          c))) 

  (define (read-word)
    (let loop ((chars '()))
      (let ((c (peek-char)))
        (cond
          ((or (eof-object? c) (char-whitespace? c))
           (apply string (reverse chars)))
          (else
           (read-char)
           (loop (cons c chars)))))))

  (let loop ((words '()))
    (let ((c (skip-spaces)))
      (cond
        ((eof-object? c) (reverse words))
        (else (loop (cons (read-word) words)))))))
