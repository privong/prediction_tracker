#lang racket/base
; scoring_rules.rkt
;
; Compute scores for probabilistic predictions
; https://en.wikipedia.org/wiki/Scoring_rule#Proper_scoring_rules

(provide brier-score
         log-score)

(require math)

; compute Brier score
; f - forecast probability, [0, 1]
; o - actual outcome, 0 or 1
(define (brier-score f o)
    (expt (- f o) 2))

; compute logarithmic score
; L(r,i) = ln(r_i)
(define (log-score f o)
    (cond
        [(eq? o 1) (log f)]
        [(eq? o 0) (log (- 1 f))]))

