require(dplyr)

calcProb <- function(df) {
  total = (1 / df$H.Odds) + (1 / df$X.Odds) + (1 / df$A.Odds)
  df$H.P = (1 / df$H.Odds) / total
  df$X.P = (1 / df$X.Odds) / total
  df$A.P = (1 / df$A.Odds) / total
  
  return(df)
}

kelly <- function(winP, winOdds) {
  ((winP * winOdds) - 1) / (winOdds - 1) * 100
}

kellyLogUtil <- function(winP, drawP, loseP, winOdds) {
  winP * log(100 + ((winOdds-1) * x)) + drawP * log(100) + loseP * log(100 - x) 
}

calcKelly <- function(df, fraction = 0.25, bankroll = 10, minBet = 0.01, round = c("floor", "ceiling")) {
  
  roundmethod <- match.arg(round)
  
  stakes <- lapply(unique(df$Match), function(y) {
    ss <- df[df$Match==y,]
    H.Odds = ss$H.Odds
    X.Odds = ss$X.Odds
    A.Odds = ss$A.Odds
    H.P = ss$H.P
    X.P = ss$X.P
    A.P = ss$A.P
    
    home_kelly <- kelly(d$H.P, d$H.Odds)
    draw_kelly <- kelly(d$X.P, d$X.Odds)
    away_kelly <- kelly(d$A.P, d$A.Odds)
    
    home_stake <- home_kelly / 100 * fraction * bankroll
    draw_stake <- draw_kelly / 100 * fraction * bankroll
    away_stake <- away_kelly / 100 * fraction * bankroll
    
    data.frame(Match = y, H.Kelly = home_kelly, H.Stake = home_stake, X.Kelly = draw_kelly, X.Stake = draw_take, A.Kelly = away_kelly, A.Stake = away_stake)
  }) %>%
    plyr::rbind.fill()
  
  # round stake to unit
  if(roundmethod == "floor") {
    stakes$H.Stake <- minBet * floor(stakes$H.Stake / minBet)
    stakes$X.Stake <- minBet * floor(stakes$X.Stake / minBet)
    stakes$A.Stake <- minBet * floor(stakes$A.Stake / minBet)
  } else {
    stakes$H.Stake <- minBet * ceiling(stakes$H.Stake / minBet)
    stakes$X.Stake <- minBet * ceiling(stakes$X.Stake / minBet)
    stakes$A.Stake <- minBet * ceiling(stakes$A.Stake / minBet)
  }
  
  # calculate expected profit
  stakes$H.Exp.Profit <- round(stakes$H.Stake * (df$H.Odds - 1), 2)
  stakes$X.Exp.Profit <- round(stakes$X.Stake * (df$X.Odds - 1), 2)
  stakes$A.Exp.Profit <- round(stakes$A.Stake * (df$A.Odds - 1), 2)
  
  stakes$H.Odds <- df$H.Odds
  stakes$X.Odds <- df$X.Odds
  stakes$A.Odds <- df$A.Odds
  
  stakes %>%
    select(Match, H.Odds, X.Odds, A.Odds, H.Kelly, D.Kelly, A.Kelly, H.Stake, D.Stake, A.Stake, H.Exp.Profit, D.Exp.Profit, A.Exp.Profit)
}

calcKellyDNB <- function(df, fraction = 0.25, bankroll = 10, minBet = 0.01, round = c("floor", "ceiling"), adjust = FALSE) {
  
  roundmethod <- match.arg(round)
  
  stakes <- lapply(unique(df$Match), function(y) {
    ss <- df[df$Match==y,]
    H.Odds = ss$H.Odds
    A.Odds = ss$A.Odds
    H.P = ss$H.P
    X.P = ss$X.P
    A.P = ss$A.P
    
    suppressWarnings(
      home <- lapply(seq(-99, 99, by = 1), function(x) {
        k <- H.P * log(100 + ((H.Odds-1) * x)) + X.P * log(100) + A.P * log(100 - x)
        data.frame(x, k)
      }) %>%
        plyr::rbind.fill()
    )
    
    suppressWarnings(
      away <- lapply(seq(-99, 99, by = 1), function(x) {
        k <- A.P * log(100 + ((A.Odds-1) * x)) + X.P * log(100) + H.P * log(100 - x)
        data.frame(x, k)
      }) %>%
        plyr::rbind.fill()
    )
    
    home_kelly <- round(home[which.max(home$k),]$x, 2)
    home_stake <- home_kelly / 100 * fraction * bankroll
    away_kelly <- round(away[which.max(away$k),]$x, 2)
    away_stake <- away_kelly / 100 * fraction * bankroll
    
    # home_stake <- as.numeric(ifelse(home_stake>0, formatC(home_stake, digits = 2, format = "f"), NA))
    # away_stake <- as.numeric(ifelse(away_stake>0, formatC(away_stake, digits = 2, format = "f"), NA))
    
    data.frame(Match = y, H.Kelly = home_kelly, H.Stake = home_stake, A.Kelly = away_kelly, A.Stake = away_stake)
  }) %>%
    plyr::rbind.fill()
  
  # round stake to unit
  if(roundmethod == "floor") {
    stakes$H.Stake <- minBet * floor(stakes$H.Stake / minBet)
    stakes$A.Stake <- minBet * floor(stakes$A.Stake / minBet)
  } else {
    stakes$H.Stake <- minBet * ceiling(stakes$H.Stake / minBet)
    stakes$A.Stake <- minBet * ceiling(stakes$A.Stake / minBet)
  }
  
  # calculate expected profit
  stakes$H.Exp.Profit <- round(stakes$H.Stake * (df$H.Odds - 1), 2)
  stakes$A.Exp.Profit <- round(stakes$A.Stake * (df$A.Odds - 1), 2)
  
  stakes$H.Odds <- df$H.Odds
  stakes$A.Odds <- df$A.Odds
  
  stakes %>%
    select(Match, H.Odds, A.Odds, H.Kelly, A.Kelly, H.Stake, A.Stake, H.Exp.Profit, A.Exp.Profit)
}


pickKellyDNB <- function(df, minKelly = 10, minEdge = 10) {
  df$Pick <- ifelse(df$H.Kelly > minKelly & df$H.Kelly - df$A.Kelly > minEdge, "H",
     ifelse(df$A.Kelly > minKelly & df$A.Kelly - df$H.Kelly > minEdge, "A",
            NA))
  
  return(df)
}

adjustKelly <- function(df, bankroll = 10, minBet = 0.01, round = c("floor", "ceiling")) {
  
  roundmethod <- match.arg(round)
  
  df$Stake <- ifelse(df$Pick == "H", df$H.Stake,
    ifelse(df$Pick == "A", df$A.Stake,
    0))
  
  scalar <- bankroll / sum(df$Stake, na.rm=T)
  
  df$Stake = round(df$Stake * scalar, 2)
  
  # round stake to unit
  if(roundmethod == "floor") {
    df$Stake <- minBet * floor(df$Stake / minBet)
  } else {
    df$Stake <- minBet * ceiling(df$Stake / minBet)
  }
  
  df$Exp.Profit <- round(ifelse(df$Pick == "H", df$H.Stake * (df$H.Odds-1),
                     ifelse(df$Pick == "A", df$A.Stake * (df$A.Odds-1),
                            0)), 2)
  
  df %>%
    select(-H.Stake, -A.Stake, -H.Exp.Profit, -A.Exp.Profit)
}

validateKellyDNB <- function(bets, results = NULL) {
  
  # df <- left_join(stakes, results, by = "Match")
  
  bets$Profit <- suppressWarnings(
    ifelse(bets$Pick == "H" & bets$Result == "H", bets$Exp.Profit,
      ifelse(bets$Pick == "H" & bets$Result == "D", 0,
      ifelse(bets$Pick == "H" & bets$Result == "A", -bets$Stake,
      ifelse(bets$Pick == "A" & bets$Result == "A", bets$Exp.Profit,
      ifelse(bets$Pick == "A" & bets$Result == "D", 0,
      ifelse(bets$Pick == "A" & bets$Result == "H", -bets$A.Stake, NA))))))
  )
  
  net <- sum(bets$Profit, na.rm=T)
  
  if(net > 0) {
    print(paste0("Total profit: £", formatC(net, digits = 2, format = "f")))
  } else {
    print(paste0("Total loss: £", formatC(net, digits = 2, format = "f")))
  }
 
  bets %>%
    select(Match, H.Odds, A.Odds, Pick, Result, Profit)
}


vizKellyDNB <- function(df) {
  
  H.Odds = df$H.Odds
  A.Odds = df$A.Odds
  H.P = df$H.P
  X.P = df$X.P
  A.P = df$A.P
  
  home <- suppressWarnings(
    lapply(seq(-99, 99, by = 1), function(x) {
      k <- H.P * log(100 + ((H.Odds-1) * x)) + X.P * log(100) + A.P * log(100 - x)
      data.frame(x, k)
    }) %>%
      plyr::rbind.fill()
  )
  
  away <- suppressWarnings(
    lapply(seq(-99, 99, by = 1), function(x) {
      k <- A.P * log(100 + ((A.Odds-1) * x)) + X.P * log(100) + H.P * log(100 - x)
      data.frame(x, k)
    }) %>%
      plyr::rbind.fill()
  )
  
  # plot
  par(mfrow = c(2,1), oma = c(2, 2, 2, 1), mar = c(1, 1, 0, 0), mgp = c(2, 1, 0), xpd = FALSE)
  # home
  plot(k ~ x, data = home, type='l', lwd = 2, axes = FALSE, xlab = "", ylab = "")
  k_max <- home[which.max(home$k),]$x
  abline(v = k_max, col="red")
  abline(v = 0, lty=2)
  axis(side = 1, tick = F, labels = FALSE)
  axis(side = 2)
  box(which = "plot", bty = "l")
  text(-95, max(home$k, na.rm=T), "Home")
  if(k_max > 0) { 
    text(k_max - 10, min(home$k, na.rm=T) + (diff(range(away$k, na.rm=T) / 2)), paste0(k_max, "%"), cex = 1.5) 
  } else {
    text(k_max + 20, min(home$k, na.rm=T) + (diff(range(home$k, na.rm=T) / 2)), "NO BET", cex = 1.5)
  }
  # away
  plot(k ~ x, data = away, type='l', lwd = 2, axes = FALSE, xlab = "", ylab = "")
  k_max <- away[which.max(away$k),]$x
  abline(v = k_max, col="red")
  abline(v = 0, lty=2)
  axis(side = 1)
  axis(side = 2)
  box(which = "plot", bty = "l")
  text(-95, max(away$k, na.rm=T), "Away")
  if(k_max > 0) { 
    text(k_max - 10, min(away$k, na.rm=T) + (diff(range(away$k, na.rm=T) / 2)), paste0(k_max, "%"), cex = 1.5) 
  } else {
    text(k_max + 20, min(away$k, na.rm=T) + (diff(range(away$k, na.rm=T) / 2)), "NO BET", cex = 1.5)
  }
  # titles
  title(main = df$Match, ylab = "f (x)", xlab = "Kelly Criterion (%)", outer = TRUE, line = 1)
}
