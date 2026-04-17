;;; Build script for Chez Scheme implementation

(import (chezscheme))

;; Compile all libraries and the main program
(parameterize ([library-directories (list "./src")]
               [library-extensions (list (cons ".ss" ".so"))]
               [compile-imported-libraries #f]
               [optimize-level 3])
  
  ;; Ensure build directory exists
  (unless (file-exists? "_build")
    (mkdir "_build"))
  
  ;; Compile each library to _build/
  (printf "Compiling libraries...\n")
  (compile-library "src/answers.ss" "_build/answers.so")
  (compile-library "src/parallel.ss" "_build/parallel.so") 
  (compile-library "src/tarjan.ss" "_build/tarjan.so")
  (compile-library "src/loops.ss" "_build/loops.so"))

;; Now compile the main program
(parameterize ([library-directories (list "./_build")]
               [compile-imported-libraries #f]
               [optimize-level 3])
  (printf "Compiling main program...\n")
  (compile-program "src/perms.ss" "_build/perms.so"))

(printf "Build complete.\n")