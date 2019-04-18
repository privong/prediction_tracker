#lang racket/base

; Add new predictions, update predictions, add outcomes

(require racket/cmdline)
(require racket/date)
(require db)

(define progname "update_predictions.rkt")

; load configuration file
(require (file "../config.rkt"))

; give us the date in YYYY-MM-DD format
(date-display-format 'iso-8601)

(define (pending)
  (write-string "Functionality not yet implemented.\n"))

; set up command line arguments
(define mode (command-line
              #:program "update_prediction"
              #:args ([updatetype "help"]) ; (add, update, outcome help)
              updatetype))

; print some help
(define (printhelp)
  (write-string (string-append "Usage: "
                               progname " MODE\n\n"))

  (write-string "Where MODE is one of:\n")
  (write-string " add\t\t - add new prediction to database.\n")
  (write-string " update\t\t - update a prediction with results.\n")
  (write-string " list-open\t - Show all predictions that do not yet have outcomes.\n")
  (write-string " score\t\t - Calculate and display Brier scores for predictions with logged outcomes.\n")
  (write-string " help\t\t - Show this help message.\n")
  (write-string "\nCopyright 2019 George C. Privon\n"))

; set up a condensed prompt for getting information
(define (getinput prompt)
  (write-string prompt)
  (write-string ": ")
  (read-line))

; add a new prediction
(define (addpred)
  ; manually get incremented ID
  (define nID (+ 1
                (query-value conn "SELECT ID FROM predictions order by ID desc limit 1")))
  (define prediction (getinput "Enter the prediction"))
  (define fprob (getinput "What is your forecast probability? "))
  (define comments (getinput "Comments on the forecast"))
  (define categories (getinput "Enter any categories (comma-separated)"))
  (define date (getinput "Enter the date of the forecast (YYYY-MM-DD)"))
  (query-exec conn "INSERT INTO predictions (ID, date, prediction, forecast, comments, categories) values (?,?, ?, ?, ?, ?)"
              nID date prediction fprob comments categories))

; is the outcome of a specified prediction known?
(define (knownoutcome? ID)
  (number? (query-value conn
                        "SELECT outcome FROM predictions WHERE ID=? ORDER BY DATE DESC LIMIT 1"
                        ID)))

; print a prediction without a known outcome
; TODO: beautify output, add latest prediction to the output
(define (printpred ID)
  (cond
    [(not (knownoutcome? ID)) (print (query-row conn "SELECT ID, prediction FROM predictions where ID=? ORDER BY date ASC LIMIT 1"
                                  ID))])
  (display "\n")) ; TODO: need to remove this newline because it prints even if the outcome is known

; update a prediction
(define (updatepred ID)
  (define option (string->number (getinput "Enter \"1\" to add an updated prediction or \"2\" to enter an outcome")))
  (cond
    [(eq? option 1) (reviseprediction ID)]
    [(eq? option 2) (addoutcome ID)])
  ;TODO: get new prediction or outcome and enter into db
  )

; add a new forecast to an existing prediction
(define (reviseprediction ID)
  (pending)
  )

; enter an outcome
(define (addoutcome ID)
  (define outcome (string->number (getinput "What is the outcome (0 for didn't happen, 1 for happened)")))
  (define outcomedate (getinput "What was the date of the outcome (YYYY-MM-DD)"))
  (define comments (getinput "Comments on the outcome"))
  (cond
    [(not (or (eq? outcome 0) (eq? outcome 1))) (error "Outcome must be 0 or 1.\n")])
  (query-exec conn "INSERT INTO predictions (ID, date, outcome, comments) values (?, ?, ?, ?, ?)"
              ID outcomedate outcome comments))

; enter an outcome for a prediction
(define (showoutcome)
  (pending))

; print open predictions
(define (printopen)
  (define uIDs (query-list conn
                           "SELECT DISTINCT ID FROM predictions"))
  (map printpred uIDs))

; find unresolved predictions
(define (findpending)
  (printopen)
  (define upID (getinput "Please enter a prediction number to edit (enter 0 or nothing to exit)"))
  (cond
    [(eq? (string->number upID) 0) (exit)]
    [(string->number upID) (updatepred (string->number upID))]
    [else (exit)]))

; compute Brier score for all predictions with outcomes
(define (score)
  (pending)
  )
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
  [(regexp-match "score" mode) (score)]
  [else (error(string-append "Unknown mode. Try " progname " help\n\n"))])

; close the databse
(disconnect conn)