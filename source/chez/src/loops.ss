;; Loops algorithm for cycle counting

(library (loops)
  (export
    make-relations
    reset!
    unite!
    set-count
    name)
  (import
    (chezscheme))

  (define-record-type
    (relations %make-relations relations?)
    (fields
      (mutable ends)
      (mutable sets))
    (protocol
      (lambda (new)
        (lambda (n)
          (new (make-fxvector n 0) 0)))))

  (define (make-relations n)
    (let
      ([rel (%make-relations n)])
      (reset! rel n)
      rel))

  (define (reset! rel n)
    (relations-sets-set! rel 0)
    (let
      ([ends (relations-ends rel)])
      (do
        ([i 0 (fx+ i 1)])
        ((fx= i n))
        (fxvector-set! ends i i))))

  (define (unite! rel a b)
    (let*
      ([ends (relations-ends rel)]
        [ea (fxvector-ref ends a)]
        [eb (fxvector-ref ends b)])
      (if (fx= ea b)
        (relations-sets-set! rel
          (fx+ (relations-sets rel) 1))
        (begin
          (fxvector-set! ends ea eb)
          (fxvector-set! ends eb ea)))))

  (define (set-count rel)
    (relations-sets rel))

  (define name "Loops")
  )
