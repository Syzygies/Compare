(library (parallel)
  (export swap parallel-map)
  (import (chezscheme))

  (define (swap arr i j)
    (let ((temp (fxvector-ref arr i)))
      (fxvector-set! arr i (fxvector-ref arr j))
      (fxvector-set! arr j temp)))

  (define (parallel-map cores run tasks)
    (let* ((tasks (list->vector tasks))
        (count (vector-length tasks))
        (next (box 0))
        (order (make-fxvector count 0))
        (results (make-vector count)))

      (do ((i 0 (fx+ i 1)))
        ((fx= i count))
        (fxvector-set! order i i))

      (let ((shuffle (lambda (arr)
              (do ((i (fx- count 1) (fx- i 1)))
                ((fx< i 1))
                (let ((j (random (fx+ i 1))))
                  (swap arr i j))))))
        (shuffle order))

      (let ((worker (lambda ()
              (let loop ()
                (let ((index (atomic-fetch-add! next 1)))
                  (when (fx< index count)
                    (let ((index (fxvector-ref order index)))
                      (vector-set! results index (run (vector-ref tasks index)))
                      (loop))))))))

        (let ((domains (map (lambda (_) (fork-thread worker))
                (make-list (fx- cores 1) #f))))
          (worker)
          (for-each thread-join domains)))

      (vector->list results)))

  (define (atomic-fetch-add! box-ref delta)
    (let loop ()
      (let* ((old (unbox box-ref))
          (new (fx+ old delta)))
        (if (box-cas! box-ref old new)
          old
          (loop))))))