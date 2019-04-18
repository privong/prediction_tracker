# Prediction Tracker

Tools to maintain and interograte a database of predictions and results.

## Usage

Before using, copy `config.rkt.example` to `config.rkt` and edit it with your desired database location.
Then run `create_database.rkt` to create the sqlite3 file and create the `predictions` table.

`update_predictions.rkt help` will provide instructions on how to add/update predictions, log outcomes, and compute Brier scores for those predictions.
Note that functionality is currently limited to adding new predictions and showing open predictions.
Updating predictions, logging outcomes, and scoring are not yet available.

## Requirements

* [Racket](https://racket-lang.org/) (tested with Racket 7.2)
* [`db` library](https://docs.racket-lang.org/db/index.html) and sqlite3 native library.

