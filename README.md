# Prediction Tracker

Tools to maintain and interograte a database of predictions and results.

## Usage

Before using, copy `config.rkt.example` to `config.rkt` and edit it with your desired database location.
Then run `create_database.rkt` to create the sqlite3 file and create the `predictions` table.

## Requirements

* [Racket](https://racket-lang.org/) (tested with Racket 7.2)
* [`db` library](https://docs.racket-lang.org/db/index.html) and sqlite3 native library.

