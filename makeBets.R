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
minBet = 0.05 #minimum betting unit, in £
roundMethod = "ceiling" #should suggested bets be
minKelly = 10 #minimum full Kelly % required to pick, in %
minEdge = 10 #minimum difference between Home Kelly % and Away Kelly % required to pick
adjust = FALSE #should stakes be adjusted so that picks use total bankroll?

# calculate Kelly stakes
bets <- odds %>%
  calcProb %>%
  calcKellyDNB(kellyFraction, bankroll, minBet, roundMethod, adjust) %>%
  pickKellyDNB(minKelly, minEdge) %>% 
  adjustKelly(bankroll, minBet, roundMethod)

# write bets to csv
write.csv(bets, "bets.csv", na = "", row.names = FALSE)

# manually add results to column in csv
bets <- read.csv("~/Desktop/bets.csv")

# calculate total profit / loss
validateKellyDNB(bets)
