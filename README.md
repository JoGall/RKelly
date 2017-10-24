RKelly
=======

Still in progress...

Optimised betting for Draw No Bet markets using the log utility form of the Kelly criterion.

Implied probabilities of home win, draw, and away win are computed from bookmakers' 1-X-2 odds. For example:

if: Odds<sub>home</sub> = 1.67, Odds<sub>draw</sub> = 3.00, Odds<sub>away</sub> = 8.00;

then: P<sub>home</sub> = (1 / 1.67) / ((1/1.67) + (1/3.00) + (1/8.00)) = 0.67 / 1.057 = 56.7%

P<sub>draw</sub> = (1 / 3.00) / ((1/1.67) + (1/3.00) + (1/8.00)) = 0.67 / 1.057 = 31.5%

P<sub>away</sub> = (1 / 8.00) / ((1/1.67) + (1/3.00) + (1/8.00)) = 0.67 / 1.057 = 11.8%

P_{home} = \frac{(1 / Odds_{home})}{(1 / Odds_{home}) + (1 / Odds_{draw}) + (1 / Odds_{away})}

Example functions are included to scrape odds from bookmakers, but check you operate within the terms of service by doing so. Although [some analysts](https://twitter.com/MC_of_A) develop their own models for predicting probabilities, it's hard to do better than the bookies. In fact, the [Wisdom of Crowds](https://en.wikipedia.org/wiki/The_Wisdom_of_Crowds) suggests averaging across several bookmakers might provide the most reliable estimates.

max [ .6 * ln(100 + .43x) + .2 * ln(100) + .2 * ln(100 - x)]

Mostly conceived just to use the name `RKelly`.

#### Install dependencies

Requires an installation of [R](https://cran.r-project.org/mirrors.html) and [PostgreSQL](https://www.postgresql.org/download/), and R packages `dplyr` and [`quantmod`](https://github.com/joshuaulrich/quantmod) R package:
```R
require(dplyr)
require(devtools)
devtools::install_github("joshuaulrich/quantmod")
```

#### Set parameters in ./config.sh
Set global parameters in './config.sh', including directory database parameters (host, user, database, password), start date to return stock data from, and a list of ticker [symbols](https://en.wikipedia.org/wiki/Ticker_symbol) you're interested in getting data for. See [`./R/build_my_symbols_ex.R`](https://github.com/JoGall/quantdb/blob/master/R/build_my_symbols_ex.R) script for an example of getting symbols using `quantmod` and [`my_symbols.txt`](https://github.com/JoGall/quantdb/blob/master/my_symbols.txt) for an example file.

#### Initial database build using ./buildDB.sh
After setting global parameters, build a new database (or overwrite an existing database) using:

`./buildDB.sh`

#### Update database using ./updateDB.sh
Once a database has been created, you can update it using:

`./updateDB.sh`

This could be automated e.g. weekly with a [job scheduler](https://en.wikipedia.org/wiki/List_of_job_scheduler_software).


-----

###### Contact

* **website / blog:** [jogall.github.io](https://jogall.github.io/)
* **email:**  joedgallagher [at] gmail [dot] com
* **twitter:**  @joedgallagher
