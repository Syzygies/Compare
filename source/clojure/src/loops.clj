(ns loops)

(set! *warn-on-reflection* true)
(set! *unchecked-math* :warn-on-boxed)

(def algorithm-name "Loops")

(defn create
  ^ints [^long n]
  (let [ends (int-array n)]
    (dotimes [i n]
      (aset-int ends i i))
    ends))

(defn unite!
  [^objects loops-state ^long a ^long b]
  (let [^ints ends (aget loops-state 0)
        ^longs loops-ref (aget loops-state 1)
        a-end (aget ends a)
        b-end (aget ends b)]
    (if (= a-end b)
      (aset loops-ref 0 (inc (aget loops-ref 0)))
      (do
        (aset-int ends a-end b-end)
        (aset-int ends b-end a-end)))))

(defn reset-state!
  [^ints ends ^longs loops-ref ^long n]
  (dotimes [i n]
    (aset-int ends i i))
  (aset loops-ref 0 0))

(defn set-count
  ^long [^longs loops-ref]
  (aget loops-ref 0))