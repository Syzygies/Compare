;; Signed Permutation Cycle Counting

(import (chezscheme)
  (parallel)
  (answers))

; Select Tarjan or Loops
(import (tarjan))

(define version 1)


;; Generate all prefix combinations
(define (prefixes n k)
  (let ([rest (iota n)])
    (let pick ([k k] [prefix '()] [rest rest])
      (if (= k 0)
        (list (append prefix rest))
        (apply append
          (map (lambda (x)
              (let ([sans-x (filter (lambda (y) (not (= y x))) rest)])
                (pick (- k 1) (cons x prefix) sans-x)))
            rest))))))

;; Heap's algorithm for generating permutations
(define (heap-permute! perm j callback)
  (let ([n (vector-length perm)])
    (let generate ([k (- n 1)])
      (if (< k j)
        (callback perm)
        (begin
          (generate (- k 1))
          (do ([i j (+ i 1)])
            ((>= i k))
            (if (even? (- j k))
              (swap perm j k)
              (swap perm i k))
            (generate (- k 1))))))))

;; Count cycles in a signed permutation
(define (count-cycles n perm signs rel)
  (reset! rel (* 2 n))
  (do ([i 0 (+ i 1)])
    ((= i n))
    (let* ([j (vector-ref perm i)]
        [i0 (* 2 i)]
        [i1 (+ i0 1)]
        [j0 (* 2 j)]
        [j1 (+ j0 1)])
      (if (not (zero? (bitwise-and signs (bitwise-arithmetic-shift-left 1 i))))
        (begin
          (unite! rel i0 j1)
          (unite! rel i1 j0))
        (begin
          (unite! rel i0 j0)
          (unite! rel i1 j1)))))
  (set-count rel))

;; Tally cycles for all sign combinations
(define (tally-cycles! n perm tally rel)
  (let ([max-signs (bitwise-arithmetic-shift-left 1 n)])
    (do ([signs 0 (+ signs 1)])
      ((= signs max-signs))
      (let* ([cycles (count-cycles n perm signs rel)]
          [index (- (* 2 n) cycles)])
        (vector-set! tally index (+ (vector-ref tally index) 1))))))

;; Process one parcel
(define (process-parcel n k perm)
  (let* ([perm (list->vector perm)]
      [tally (make-vector (* 2 n) 0)]
      [rel (make-relations (* 2 n))])

    (heap-permute! perm k
      (lambda (p) (tally-cycles! n p tally rel)))

    tally))

(define (vector-add! dest src)
  (let ([len (vector-length dest)])
    (do ([i 0 (+ i 1)])
      ((= i len))
      (vector-set! dest i (+ (vector-ref dest i)
          (vector-ref src i))))))

(define (compute-tally n prefix cores)
  (let* ([parcels (prefixes n prefix)]
      [parcel-results (parallel-map cores 
          (lambda (p) (process-parcel n prefix p))
          parcels)]
      [result (make-vector (* 2 n) 0)])
    (for-each (lambda (parcel-result) 
        (vector-add! result parcel-result))
      parcel-results)
    result))

(define (print-vector vec)
  (let ([len (vector-length vec)])
    (do ([i 0 (+ i 1)])
      ((= i len))
      (display (vector-ref vec i))
      (when (< i (- len 1))
        (display " ")))
    (newline)))

;; Entry point
(define (main args)
  (let ([actual-args (cond
          [(and (> (length args) 1) (equal? (cadr args) "--"))
            (cddr args)]
          [(> (length args) 3)
            (cdr args)]
          [else args])])
    (if (not (= (length actual-args) 3))
      (begin
        (display "Error: Required arguments: n prefix cores\n" 
          (current-error-port))
        (exit 1))
      (let* ([n (string->number (list-ref actual-args 0))]
          [prefix (string->number (list-ref actual-args 1))]
          [cores (string->number (list-ref actual-args 2))])

        (printf "~a v~a, n = ~a, prefix = ~a, cores = ~a\n" 
          name version n prefix cores)

        (let* ([result (compute-tally n prefix cores)]
            [expected (if (<= n 12) (vector-ref answers n) #f)])

          (print-vector result)

          (cond
            [(> n 12) (display "?\n")]
            [(equal? (vector->list result) expected) (display "✓\n")]
            [else 
              (display "✗\n")
              (for-each (lambda (x) (display x) (display " ")) expected)
              (newline)]))))))

(when (or (> (length (command-line)) 1) 
    (and (= (length (command-line)) 1) 
      (not (member (car (command-line)) '("perms.ss" "perms.so")))))
  (main (command-line)))