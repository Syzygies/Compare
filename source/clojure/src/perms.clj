(ns perms
  (:require [worker :refer [algorithm-name]]
            [parallel]
            [answers])
  (:gen-class))

(def version 1)

(defn enum-prefixes
  [n k]
  (if (zero? k)
    [[]]
    (for [prefix (enum-prefixes n (dec k))
          x (range n)
          :when (not (some #{x} prefix))]
      (cons x prefix))))

(defn run-parcels
  [n k cores]
  (let [zero (long-array (* 2 n))
        prefixes (enum-prefixes n k)
        results (parallel/parallel-map cores zero 
                                       #(worker/run-prefix n k %)
                                       prefixes)]
    (if (empty? results)
      zero
      (reduce (fn [^longs acc ^longs tally]
                (dotimes [i (alength acc)]
                  (aset acc i (+ (aget acc i) (aget tally i))))
                acc)
              results))))

(defn parse-args
  [args]
  (when (= 3 (count args))
    (try
      (let [n (Long/parseLong (nth args 0))
            prefix (Long/parseLong (nth args 1))
            cores (Long/parseLong (nth args 2))]
        [n prefix cores])
      (catch Exception _ nil))))

(defn -main
  [& args]
  (if-let [[n prefix cores] (parse-args args)]
    (do
      (println (format "%s v%d, n = %d, prefix = %d, cores = %d"
                       algorithm-name version n prefix cores))
      (let [result (run-parcels n prefix cores)
            result-vec (vec result)]
        (println (clojure.string/join " " result-vec))
        (answers/check n result-vec)))
    (do
      (binding [*out* *err*]
        (println "Required arguments: n prefix cores"))
      (System/exit 1))))