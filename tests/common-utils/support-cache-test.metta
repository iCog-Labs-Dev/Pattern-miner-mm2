;; TEST-AUX src/common-utils/utils.metta

(Inheritance Allen human)
(Inheritance Bob human)
(Inheritance Allen ugly)

;; Two independent callers request the same candidate. They receive separate
;; contextual results while sharing one support-cache entry.
(support-probe first ((Inheritance (var 0) human)))
(support-probe second ((Inheritance (var 0) human)))
(support-probe zero ((Inheritance (var 0) missing)))

;; A pre-existing cache value proves that the gate can serve a hit without the
;; corresponding database query matching any facts.
(support-cache ((Inheritance (var 0) precomputed)) 77)
(support-probe warm ((Inheritance (var 0) precomputed)))

(exec (freq 000 call-support-gate)
  (, (support-probe $context $candidate)
     ((support-gate
        cached
        (support-probe $context $candidate)
        $context
        $candidate
        (freq 010 test-cache-hit)
        (freq 020 test-count-miss)
        (freq 030 test-deliver)
        -> support-probe-result)
      $gate-p $gate-t))
  (O (+ (exec (freq 001 run-support-gate) $gate-p $gate-t))))

(EXPECTED-RESULT first-result (support-probe-result first ((Inheritance (var 0) human)) 2))
(EXPECTED-RESULT second-result (support-probe-result second ((Inheritance (var 0) human)) 2))
(EXPECTED-RESULT zero-result (support-probe-result zero ((Inheritance (var 0) missing)) 0))
(EXPECTED-RESULT warm-result (support-probe-result warm ((Inheritance (var 0) precomputed)) 77))
(EXPECTED-RESULT shared-cache (support-cache ((Inheritance (var 0) human)) 2))
