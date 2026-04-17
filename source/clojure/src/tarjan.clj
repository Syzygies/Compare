(ns tarjan)

(set! *warn-on-reflection* true)
(set! *unchecked-math* :warn-on-boxed)

(def algorithm-name "Tarjan")

(defn create
  ^ints [^long n]
  (let [root (int-array n)]
    (dotimes [i n]
      (aset-int root i i))
    root))

(defn find-root
  ^long [^ints root ^long a ^ints path-scratch]
  (loop [current a
         path-len 0]
    (let [parent (aget root current)]
      (if (= parent current)
        (do
          (dotimes [i path-len]
            (aset-int root (aget path-scratch i) current))
          current)
        (do
          (aset-int path-scratch path-len current)
          (recur parent (inc path-len)))))))

(defn unite!
  [^objects tarjan-state ^long a ^long b]
  (let [^ints root (aget tarjan-state 0)
        ^longs sets-ref (aget tarjan-state 1)
        ^ints path-scratch (aget tarjan-state 2)
        a-root (find-root root a path-scratch)
        b-root (find-root root b path-scratch)]
    (when (not= a-root b-root)
      (aset-int root a-root b-root)
      (aset sets-ref 0 (dec (aget sets-ref 0))))))

(defn reset-state!
  [^ints root ^longs sets-ref ^long n]
  (dotimes [i n]
    (aset-int root i i))
  (aset sets-ref 0 n))

(defn set-count
  ^long [^longs sets-ref]
  (aget sets-ref 0))