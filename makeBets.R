source("~/Dropbox/github/RKelly/getOdds.R")
source("~/Dropbox/github/RKelly/kellyFuns.R")

# retrieve odds from Coral.co.uk
# c("http://sports.coral.co.uk/football/england/carabao-cup",
# "http://sports.coral.co.uk/football/spain/copa-del-rey",
# "http://sports.coral.co.uk/football/scotland/ladbrokes-premiership",
# "http://sports.coral.co.uk/football/italy/primavera-cup",
# "http://sports.coral.co.uk/football/germany/dfb-pokal",
# "http://sports.coral.co.uk/football/france/coupe-de-la-ligue",
# "http://sports.coral.co.uk/football/netherlands/knvb-cup",
# "http://sports.coral.co.uk/football/european-a-z/portugal/liga-de-honra")

# Europe
# c("http://sports.coral.co.uk/football/uefa-club-comps/champions-league",
# "http://sports.coral.co.uk/football/uefa-club-comps/europa-league")

# leagues
urls <- c("http://sports.coral.co.uk/football/england/premier-league",
          "http://sports.coral.co.uk/football/england/championship",
          "http://sports.coral.co.uk/football/spain/la-liga",
          "http://sports.coral.co.uk/football/germany/bundesliga",
          "http://sports.coral.co.uk/football/scotland",
          "http://sports.coral.co.uk/football/france",
          "http://sports.coral.co.uk/football/italy/serie-a",
          "http://sports.coral.co.uk/football/netherlands",
          "http://sports.coral.co.uk/football/european-a-z/portugal/primeira-liga")

# get DNB odds for all matches played today
odds2 <- getOdds1X2(urls, href = TRUE) %>%
  filter(grepl("Today", KO)) %>%
  getOddsDNB() %>%
  na.omit

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
results <- read.csv("~/Dropbox/github/RKelly/DATA/results/2017-10-31_results.csv")

d <- left_join(picks, results, by = "Match")

# calculate total profit / loss
validateKellyDNB(d) # see returns for each pick
validateKellyDNB(d, summarise = TRUE) #sum net return

validateKellyDNB(d, summarise = TRUE) / sum(d$Stake, na.rm=T) * 100