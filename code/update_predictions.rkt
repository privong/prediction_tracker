#lang racket/base

; Add new predictions, update predictions, add outcomes

(require racket/cmdline
         racket/date
         racket/list
         db)

(require "scoring_rules.rkt")

(define progname "update_predictions.rkt")

; load configuration file
(require (file "../config.rkt"))

; give us the date in YYYY-MM-DD format
(date-display-format 'iso-8601)

; set up command line arguments
(define mode (command-line
              #:program "update_prediction"
              #:args ([updatetype "help"]) ; (add, update, list-open, list-closed, score, help)
              updatetype))

; check a date, if blank return current date
(define (verify-or-get-date datestr)
  (if (regexp-match-exact? #px"\\d{4}-\\d{2}-\\d{2}" datestr)
      datestr
      (date->string (current-date))))

; print some help
(define (printhelp)
  (displayln (string-append "Usage: "
                            progname
                            " MODE"))
  (newline)
  (displayln "Where MODE is one of:")
  (displayln " add\t\t - add new prediction to database.")
  (displayln " update\t\t - update a prediction with results.")
  (displayln " list-open\t - Show all predictions that do not yet have outcomes.")
  (displayln " list-closed\t - Show all predictions that have outcomes.")
  (displayln " score\t\t - Calculate and display Brier scores for predictions with logged outcomes.")
  (displayln " help\t\t - Show this help message.")
  (newline)
  (displayln "Copyright 2019 George C. Privon"))

; set up a condensed prompt for getting information
(define (getinput prompt)
  (display(string-append prompt ": "))
  (read-line))

; add a new prediction
(define (addpred)
  ; manually get incremented ID
  (define lastID (query-maybe-value conn "SELECT ID FROM predictions ORDER BY ID DESC LIMIT 1"))
  (define nID
    (if lastID
        (+ 1 lastID)
        (+ 1 0)))
  (define prediction (getinput "Enter the prediction"))
  (define fprob (getinput "Enter your forecast probability"))
  (define comments (getinput "Comments on the forecast"))
  (define categories (getinput "Enter any categories (comma-separated)"))
  (define date (getinput "Enter the date of the forecast (YYYY-MM-DD or leave blank to use today's date)"))
  (define enterdate (verify-or-get-date date))
  (query-exec conn "INSERT INTO predictions (ID, date, prediction, forecast, comments, categories) values (?,?, ?, ?, ?, ?)"
              nID enterdate prediction fprob comments categories))

; print a prediction given an ID. optionally write outcome and Brier score
(define (printpred ID [score #f])
  ; print out information on a specific forecast
  ; if score is true, print out outcome (1 or 0) and Brier score
  (display ((λ (myID)
            (define prediction (query-value conn "SELECT prediction FROM predictions WHERE ID=? ORDER BY date ASC LIMIT 1" myID))
            (define lastf (query-row conn "SELECT date, forecast FROM predictions WHERE ID=? AND forecast IS NOT NULL ORDER BY date DESC LIMIT 1" myID))
            (string-append (number->string myID)
                           "("
                           (vector-ref lastf 0)
                           ") "
                           prediction
                           ": "
                           (number->string (vector-ref lastf 1))))
          ID))
  (cond
    [score (display ((λ (myID)
                       (define outcome (query-value conn "SELECT outcome FROM predictions WHERE ID=? AND outcome IS NOT NULL LIMIT 1" myID))
                       (define lastf (query-value conn "SELECT forecast FROM predictions WHERE ID=? AND forecast IS NOT NULL ORDER BY date DESC LIMIT 1" myID))
                       (string-append " "
                                      (number->string outcome)
                                      " "
                                      (number->string (brier-score lastf outcome))))
                     ID))])
  (newline))

(define (printpred-with-score ID)
  (printpred ID #t))
(define (printpred-without-score ID)
  (printpred ID #f))

; update a prediction
(define (updatepred ID)
  (define option (string->number (getinput "Enter \"1\" to add an updated prediction or \"2\" to enter an outcome")))
  (cond
    [(eq? option 1) (reviseprediction ID)]
    [(eq? option 2) (addoutcome ID)]))

; add a new forecast to an existing prediction
(define (reviseprediction ID)
  (define newf (string->number (getinput "What is your new predction")))
  (define date (getinput "Enter the date of the updated prediction (YYYY-MM-DD or leave blank to use today's date)"))
  (define newfdate (verify-or-get-date date))
  (define comments (getinput "Comments on the new prediction"))
  (query-exec conn "INSERT INTO predictions (ID, date, forecast, comments) values (?, ?, ?, ?)"
              ID newfdate newf comments))

; enter an outcome
(define (addoutcome ID)
  (define lastpred (query-value conn "SELECT forecast FROM predictions WHERE ID=? ORDER BY date DESC LIMIT 1" ID))
  (define outcome (string->number (getinput "What is the outcome (0 for didn't happen, 1 for happened)")))
  (define date (getinput "Enter the date of the outcome (YYYY-MM-DD or leave blank to use today's date)"))
  (define outcomedate (verify-or-get-date date))
  (define comments (getinput "Comments on the outcome"))
  (cond
    [(not (or (eq? outcome 0) (eq? outcome 1))) (error "Outcome must be 0 or 1.\n")])
  (query-exec conn "INSERT INTO predictions (ID, date, outcome, comments) values (?, ?, ?, ?)"
              ID outcomedate outcome comments)
  (define bscore (brier-score lastpred outcome))
  (displayln (string-append "Brier score of most recent forecast: "
                               (number->string bscore))))

; print open predictions
(define (printopen)
  ; get a list of all IDs
  (define allIDs (query-list conn
                             "SELECT DISTINCT ID FROM predictions"))
  ; get list of resolved predictions
  (define resIDs (query-list conn
                             "SELECT DISTINCT ID FROM predictions WHERE outcome IS NOT NULL"))
  ; remove the IDs that are resolved, keeping only the open predictions
  (define uIDs (filter-map (λ (testID)
                             (if (member testID resIDs) #f testID))
                           allIDs))

  ; print a header and individual entry information
  (displayln "ID(DATE) PREDICTION: LATEST FORECAST")
  (map printpred-without-score uIDs))

; print resolved predictions
(define (printres [score #f])
  (define uIDs (query-list conn
                           "SELECT DISTINCT ID FROM predictions WHERE outcome IS NOT NULL"))
  (displayln "ID(DATE) PREDICTION: LAST FORECAST, OUTCOME, BRIER SCORE")
  (map printpred-with-score uIDs))

; find unresolved predictions
(define (findpending)
  (printopen)
  (define upID (getinput "Please enter a prediction number to edit (enter 0 or nothing to exit)"))
  (cond
    [(eq? (string->number upID) 0) (exit)]
    [(string->number upID) (updatepred (string->number upID))]
    [else (exit)]))

; make sure we can use the sqlite3 connection
(cond (not (sqlite3-available?))
    (error "Sqlite3 library not available."))

; open the database file
(define conn (sqlite3-connect #:database dbloc))

; determine which mode we're in
(cond
  [(regexp-match "help" mode) (printhelp)]
  [(regexp-match "add" mode) (addpred)]
  [(regexp-match "update" mode) (findpending)]
  [(regexp-match "list-open" mode) (printopen)]
  [(regexp-match "list-closed" mode) (printres)]
  [else (error (string-append "Unknown mode. Try " progname " help\n\n"))])

; close the databse
(disconnect conn)
