RKelly
=======

Optimised betting for 1-X-2 markets using the [Kelly criterion](https://www.pinnacle.com/en/betting-articles/Betting-Strategy/How-to-use-kelly-criterion-for-betting/2BT2LK6K2QWQ7QJ8) and for Draw No Bet markets using the log utility form of the Kelly criterion. Mostly conceived just to use the name `RKelly`; still very much a work in progress.

-----

Implied probabilities of a home win, draw, and away win are computed from bookmakers' 1-X-2 odds. For example:

if: Odds<sub>home</sub> = 1.67, Odds<sub>draw</sub> = 3.00, Odds<sub>away</sub> = 8.00;

then: P<sub>home</sub> = (1 / 1.67) / ((1/1.67) + (1/3.00) + (1/8.00)) = 0.67 / 1.057 = 56.7%

Example functions are included to scrape odds from bookmakers, but check you operate within the terms of service by doing so. Although [some analysts](https://twitter.com/MC_of_A) develop their own models for predicting probabilities, it's hard to do better than the bookies. In fact, the [Wisdom of Crowds](https://en.wikipedia.org/wiki/The_Wisdom_of_Crowds) suggests averaging across several bookmakers might provide the most reliable estimates of probability; functions to do such are forthcoming.

-----

###### Contact

* **website / blog:** [jogall.github.io](https://jogall.github.io/)
* **email:**  joedgallagher [at] gmail [dot] com
* **twitter:**  @joedgallagher
