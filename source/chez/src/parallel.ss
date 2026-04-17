(library (parallel)
  (export swap parallel-map)
  (import (chezscheme))

  (define (swap arr i j)
    (let ((temp (vector-ref arr i)))
      (vector-set! arr i (vector-ref arr j))
      (vector-set! arr j temp)))

  (define (parallel-map cores run tasks)
    (let* ((tasks (list->vector tasks))
        (count (vector-length tasks))
        (next (box 0))
        (order (make-vector count))
        (results (make-vector count)))

      (do ((i 0 (+ i 1)))
        ((= i count))
        (vector-set! order i i))

      (let ((shuffle (lambda (arr)
              (do ((i (- count 1) (- i 1)))
                ((< i 1))
                (let ((j (random (+ i 1))))
                  (swap arr i j))))))
        (shuffle order))

      (let ((worker (lambda ()
              (let loop ()
                (let ((index (atomic-fetch-add! next 1)))
                  (when (< index count)
                    (let ((index (vector-ref order index)))
                      (vector-set! results index (run (vector-ref tasks index)))
                      (loop))))))))

        (let ((domains (map (lambda (_) (fork-thread worker))
                (make-list (- cores 1) #f))))
          (worker)
          (for-each thread-join domains)))

      (vector->list results)))

  (define (atomic-fetch-add! box-ref delta)
    (let loop ()
      (let* ((old (unbox box-ref))
          (new (+ old delta)))
        (if (box-cas! box-ref old new)
          old
          (loop))))))