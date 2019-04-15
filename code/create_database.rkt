#lang racket/base

;; This program creates a sqlite3 database and then creates an empty table
;; for predictions.

(require db)

; create the database and create the table
(define (createdb dbloc)
  (write-string (string-append "Creating database " dbloc "\n"))
  (define conn (sqlite3-connect #:database dbloc
                                #:mode 'create))
  (query-exec conn "CREATE TABLE proposals (ID INTEGER NOT NULL,
prediction TEXT NOT NULL,
categories TEXT DEFAULT '',
forecast float,
outcome int,
comments TEXT DEFAULT '')")
  (disconnect conn)
  (write-string (string-append "Database created at " dbloc "\n")))

; load configuration file
(require (file "../config.rkt"))

; make sure we can use the sqlite3 connection
(cond (not (sqlite3-available?))
      (error "Sqlite3 library not available."))

; create the database and add the `proposals` table if it doesn't exist
(if (not (file-exists? dbloc))
    (createdb dbloc)
    (write-string "Database exists. Exiting."))
