#lang typed/racket/base
; scoring_rules.rkt
;
; Compute scores for probabilistic predictions
; https://en.wikipedia.org/wiki/Scoring_rule#Proper_scoring_rules

(provide brier-score
         log-score)

; compute Brier score
; f - forecast probability, [0, 1]
; o - actual outcome, 0 or 1
(: brier-score (-> Number Number Number))
(define (brier-score f o)
    (expt (- f o) 2))

; compute logarithmic score
; L(r,i) = ln(r_i)
(: log-score (-> Number Number Number))
(define (log-score f o)
  (+ (* o (log f)) (* (- 1 o) (log (- 1 f)))))
