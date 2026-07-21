;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; do-ji-prob-only test DB
;;
;; This fixture provides two already-computed `ji-prob-est-of` facts so the test
;; exercises only the ordered list collection behavior.
;;
;; Expected important output:
;;
;;   (do-ji-prob-of
;;       ((((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
;;        (((Inheritance (var 0) man) (Inheritance (var 0) ugly))))
;;       (0.125 0.25))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(do-ji-prob-request
    ((((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
     (((Inheritance (var 0) man) (Inheritance (var 0) ugly)))))

(ji-prob-est-of
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    0.125)

(ji-prob-est-of
    (((Inheritance (var 0) man) (Inheritance (var 0) ugly)))
    0.25)
