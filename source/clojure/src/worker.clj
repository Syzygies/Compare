(ns worker
  ; Select Tarjan or Loops
  (:require [tarjan :as rel]))

(set! *warn-on-reflection* true)
(set! *unchecked-math* :warn-on-boxed)

(def algorithm-name rel/algorithm-name)

(defn swap-arr!
  [^ints arr ^long i ^long j]
  (let [temp (aget arr i)]
    (aset-int arr i (aget arr j))
    (aset-int arr j temp)))

(defn tally-perms
  [^ints perm ^long k ^long n ^objects state]
  (let [^longs tally (aget state 0)
        ^objects rel-state (aget state 1)
        ^ints root (aget rel-state 0)
        ^longs sets-ref (aget rel-state 1)
        max-bits (bit-shift-left 1 n)
        two-n (* 2 n)]
    (letfn [(generate [^long j]
              (if (< j k)
                (dotimes [signs max-bits]
                  (rel/reset-state! root sets-ref two-n)
                  (dotimes [i n]
                    (let [perm-i (aget perm i)]
                      (if (= 1 (bit-and (bit-shift-right signs i) 1))
                        (do
                          (rel/unite! rel-state i (+ perm-i n))
                          (rel/unite! rel-state (+ i n) perm-i))
                        (do
                          (rel/unite! rel-state i perm-i)
                          (rel/unite! rel-state (+ i n) (+ perm-i n))))))
                  (let [cycles (rel/set-count sets-ref)
                        idx (- two-n cycles)]
                    (aset tally idx (unchecked-inc (aget tally idx)))))
                (do
                  (generate (dec j))
                  (loop [i k]
                    (when (< i j)
                      (if (even? (- j k))
                        (swap-arr! perm k j)
                        (swap-arr! perm i j))
                      (generate (dec j))
                      (recur (inc i)))))))]
      (generate (dec n)))))

(defn run-prefix
  ^longs [^long n ^long k prefix]
  (let [two-n (* 2 n)
        perm (int-array n)
        tally (long-array two-n)
        root (rel/create two-n)
        sets-ref (long-array 1 two-n)
        path-scratch (int-array two-n)
        rel-state (object-array [root sets-ref path-scratch])]
    (dotimes [i n]
      (aset-int perm i i))
    (loop [prefix-vals prefix
           idx 0]
      (when (seq prefix-vals)
        (let [val (first prefix-vals)
              pos (loop [j idx]
                    (if (= (aget perm j) val) j (recur (inc j))))]
          (when (not= pos idx)
            (swap-arr! perm idx pos))
          (recur (rest prefix-vals) (inc idx)))))
    (let [state (object-array [tally rel-state])]
      (tally-perms perm k n state))
    tally))
