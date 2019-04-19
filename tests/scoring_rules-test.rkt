#lang racket/base
; brier_score_test.rkt
; Unit tests for Brier score function

(require rackunit
         "../code/scoring_rules.rkt")

; Brier Score Checks
; perfect prediction for event occurring
(check-equal? (brier-score 1 1) 0 "Perfect prediction, event occurs")

; wrong prediction, event occurs
(check-equal? (brier-score 0 1) 1 "Predicted impossible, event occurs")
; wrong prediction, event doesn't occur
(check-equal? (brier-score 1 0) 1 "Predicted to happen, event doesn't happen")

; 50/50 scores
(check-equal? (brier-score 0.5 1) 0.25 "50/50 prediction, event occurs")
(check-equal? (brier-score 0.5 0) 0.25 "50/50 prediction, event doesn't occur")

; Logarithmic Score checks
(check-within (log-score 0.8 1) (log 0.8) 1e-8 "80% forecast, event occurs")
(check-within (log-score 0.8 0) (log 0.2) 1e-8 "80% forecast, event doesn't occur")