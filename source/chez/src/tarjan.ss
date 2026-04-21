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
          (new (make-fxvector n 0) n)))))

  (define (make-relations n)
    (let ([rel (%make-relations n)])
      (reset! rel n)
      rel))

  (define (reset! rel n)
    (relations-sets-set! rel n)
    (let ([root (relations-root rel)])
      (do ([i 0 (fx+ i 1)])
        ((fx= i n))
        (fxvector-set! root i i))))

  ;; Find with path compression
  (define (find-root rel a)
    (let ([root (relations-root rel)])
      (let loop ([x a])
        (let ([parent (fxvector-ref root x)])
          (if (fx= parent x)
            x
            (let ([root-x (loop parent)])
              (fxvector-set! root x root-x)
              root-x))))))

  (define (unite! rel a b)
    (let ([a-root (find-root rel a)]
        [b-root (find-root rel b)])
      (when (not (fx= a-root b-root))
        (relations-sets-set! rel (fx- (relations-sets rel) 1))
        (fxvector-set! (relations-root rel) a-root b-root))))

  (define (set-count rel)
    (relations-sets rel))

  (define name "Tarjan")
  )