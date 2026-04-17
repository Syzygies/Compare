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
          (new (make-vector n 0) 0)))))

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
        ([i 0 (+ i 1)])
        ((= i n))
        (vector-set! ends i i))))

  (define (unite! rel a b)
    (let*
      ([ends (relations-ends rel)]
        [ea (vector-ref ends a)]
        [eb (vector-ref ends b)])
      (if (= ea b)
        (relations-sets-set! rel
          (+ (relations-sets rel) 1))
        (begin
          (vector-set! ends ea eb)
          (vector-set! ends eb ea)))))

  (define (set-count rel)
    (relations-sets rel))

  (define name "Loops")
  )
