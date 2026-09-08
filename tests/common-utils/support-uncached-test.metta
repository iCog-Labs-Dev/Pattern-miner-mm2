;; TEST-AUX src/common-utils/utils.metta

(Inheritance Allen human)
(Inheritance Bob human)
(Inheritance Allen ugly)

;; Repeated candidates are intentionally counted as independent requests in
;; uncached mode. Both callers still receive the same public result shape.
(support-probe first ((Inheritance (var 0) human)))
(support-probe second ((Inheritance (var 0) human)))
(support-probe zero ((Inheritance (var 0) missing)))

(exec (freq 000 call-support-gate)
  (, (support-probe $context $candidate)
     ((support-gate
        uncached
        (support-probe $context $candidate)
        $context
        $candidate
        (freq 010 unused-cache-hit)
        (freq 020 count-support)
        (freq 030 unused-delivery)
        -> support-probe-result)
      $gate-p $gate-t))
  (O (+ (exec (freq 001 run-support-gate) $gate-p $gate-t))))

(EXPECTED-RESULT first-result (support-probe-result first ((Inheritance (var 0) human)) 2))
(EXPECTED-RESULT second-result (support-probe-result second ((Inheritance (var 0) human)) 2))
(EXPECTED-RESULT zero-result (support-probe-result zero ((Inheritance (var 0) missing)) 0))
