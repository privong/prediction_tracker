#lang racket/base
; brier_score.rkt
;
; Compute Brier score for probabilistic predictions
; https://en.wikipedia.org/wiki/Brier_score

(provide brier-score)

(require math)

; compute Brier score
; f - forecast probability, [0, 1]
; o - actual outcome, 0 or 1
(define (brier-score f o)
    (expt (- f o) 2))

