# Prediction Tracker

Tools to maintain and interrogate a database of predictions to track forecasts and outcomes.

## Usage

Before using, copy `config.rkt.example` to `config.rkt` and edit it with your desired database location.
Then run `racket create_database.rkt` to create the sqlite3 file and create the `predictions` table.

`racket update_predictions.rkt help` will provide instructions on how to add/update predictions and log outcomes. 
[Brier scores](https://en.wikipedia.org/wiki/Brier_score) are currently computed when outcomes are entered.
More comprehensive Brier score reporting will be developed in the future (score as a function of time, average Brier scores, etc.).

## Requirements

* [Racket](https://racket-lang.org/) (tested with Racket 7.2-7.3)
* [`db` library](https://docs.racket-lang.org/db/index.html) and sqlite3 native library.

