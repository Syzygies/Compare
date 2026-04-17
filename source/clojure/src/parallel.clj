(ns parallel
  (:import [java.util.concurrent Executors]))

(set! *warn-on-reflection* true)

(defn parallel-map
  [cores init f tasks]
  (if (empty? tasks)
    []
    (let [pool (Executors/newFixedThreadPool cores)
          tasks-vec (vec tasks)
          shuffled (shuffle (range (count tasks-vec)))
          futures (mapv (fn [idx]
                          (.submit pool
                                   ^Callable
                                   (fn [] (f (nth tasks-vec (nth shuffled idx))))))
                        (range (count tasks-vec)))]
      (try
        (mapv #(.get ^java.util.concurrent.Future %) futures)
        (finally
          (.shutdown pool))))))
