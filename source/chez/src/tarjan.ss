;; Tarjan's union-find algorithm for cycle counting

(library (tarjan)
  (export make-relations
    reset!
    unite!
    set-count
    name)
  (import (chezscheme))

  (define-record-type (relations %make-relations relations?)
    (fields (mutable root)
      (mutable sets))
    (protocol
      (lambda (new)
        (lambda (n)
          (new (make-vector n 0) n)))))

  (define (make-relations n)
    (let ([rel (%make-relations n)])
      (reset! rel n)
      rel))

  (define (reset! rel n)
    (relations-sets-set! rel n)
    (let ([root (relations-root rel)])
      (do ([i 0 (+ i 1)])
        ((= i n))
        (vector-set! root i i))))

  ;; Find with path compression
  (define (find-root rel a)
    (let ([root (relations-root rel)])
      (let loop ([x a])
        (let ([parent (vector-ref root x)])
          (if (= parent x)
            x
            (let ([root-x (loop parent)])
              (vector-set! root x root-x)
              root-x))))))

  (define (unite! rel a b)
    (let ([a-root (find-root rel a)]
        [b-root (find-root rel b)])
      (when (not (= a-root b-root))
        (relations-sets-set! rel (- (relations-sets rel) 1))
        (vector-set! (relations-root rel) a-root b-root))))

  (define (set-count rel)
    (relations-sets rel))

  (define name "Tarjan")
  )