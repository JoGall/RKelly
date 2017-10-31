source("~/Dropbox/github/RKelly/getOdds.R")
source("~/Dropbox/github/RKelly/kellyFuns.R")

# retrieve odds from Coral.co.uk
urls <- c("http://sports.coral.co.uk/premier-league",
          "http://sports.coral.co.uk/championship",
          "http://sports.coral.co.uk/la-liga",
          "http://sports.coral.co.uk/serie-a",
          "http://sports.coral.co.uk/football/germany/bundesliga",
          "http://sports.coral.co.uk/football/scotland",
          "http://sports.coral.co.uk/football/france",
          "http://sports.coral.co.uk/football/netherlands")

odds <- getOdds(urls)

# set Kelly parameters
bankroll = 10 #total amount to be wagered (£)
kellyFraction = 0.25 #fraction of full Kelly to be used
minKelly = 15 #minimum full Kelly % required to pick, in %
minEdge = 1 #minimum difference between Home Kelly % and Away Kelly % required to pick
minBet = 0.1 #minimum betting unit, in £
roundMethod = "ceiling" #should suggested bets be

# calculate Kelly stakes
picks <- odds %>%
  calcProb %>%
  calcKellyDNB() %>%
  calcStakeDNB(kellyFraction, bankroll, minKelly, minEdge, minBet, roundMethod)

# load results csv, e.g.
results <- read.csv("~/Dropbox/github/RKelly/DATA/results/2017-10-28_results.csv")

d <- left_join(picks, results, by = "Match")

# calculate total profit / loss
validateKellyDNB(d) # see returns for each pick
validateKellyDNB(d, summarise = TRUE) #sum net return
