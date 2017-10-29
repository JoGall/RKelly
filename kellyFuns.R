require(dplyr)

calcProb <- function(df) {
  total = (1 / df$H.Odds) + (1 / df$X.Odds) + (1 / df$A.Odds)
  df$H.P = (1 / df$H.Odds) / total
  df$X.P = (1 / df$X.Odds) / total
  df$A.P = (1 / df$A.Odds) / total
  
  return(df)
}

kelly1X2 <- function(winP, winOdds) {
  ((winP * winOdds) - 1) / (winOdds - 1) * 100
}

kellyLogUtil <- function(winP, drawP, loseP, winOdds, return_df = FALSE) {
  
  suppressWarnings(
    kelly <- lapply(seq(-99, 99, by = 1), function(x) {
      k <- winP * log(100 + ((winOdds-1) * x)) + drawP * log(100) + loseP * log(100 - x)
      data.frame(x, k)
    }) %>%
      plyr::rbind.fill()
  )
  
  if(return_df) {
    return(kelly)
  } else {
    return(kelly[which.max(kelly$k),]$x)
  }
}

calcKelly1X2 <- function(df, fraction = 0.25, bankroll = 10, minBet = 0.01, round = c("floor", "ceiling")) {
  
  roundmethod <- match.arg(round)
  
  stakes <- lapply(unique(df$Match), function(y) {
    ss <- df[df$Match==y,]
    H.Odds = ss$H.Odds
    X.Odds = ss$X.Odds
    A.Odds = ss$A.Odds
    H.P = ss$H.P
    X.P = ss$X.P
    A.P = ss$A.P
    
    home_kelly <- kelly1X2(ss$H.P, ss$H.Odds)
    draw_kelly <- kelly1X2(ss$X.P, ss$X.Odds)
    away_kelly <- kelly1X2(ss$A.P, ss$A.Odds)
    
    data.frame(Match = y, H.Kelly = home_kelly, X.Kelly = draw_kelly, A.Kelly = away_kelly)
  }) %>%
    plyr::rbind.fill()
  
  # round stake to unit
  stakes$H.Stake <- stakes$H.Kelly * fraction * bankroll
  stakes$X.Stake <- stakes$X.Kelly * fraction * bankroll
  stakes$A.Stake <- stakes$A.Kelly * fraction * bankroll
  
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
    dplyr::select(Match, H.Odds, X.Odds, A.Odds, H.Kelly, X.Kelly, A.Kelly, H.Stake, X.Stake, A.Stake, H.Exp.Profit, X.Exp.Profit, A.Exp.Profit)
}

pickKelly1X2 <- function(df, minKelly = 0, minEdge = 0) {
  # best option by Kelly
  ind <- which.max(c(df$H.Kelly, df$X.Kelly, df$A.Kelly))
  
  pick <- ifelse(ind == 1, "H", ifelse(ind == 2, "D", "A"))
  
  df$Pick <- ifelse(df$H.Kelly > minKelly & df$H.Kelly - df$A.Kelly > minEdge, "H",
                    ifelse(df$A.Kelly > minKelly & df$A.Kelly - df$H.Kelly > minEdge, "A",
                           NA))
  
  return(df)
}

calcKellyDNB <- function(df) {
  
  lapply(unique(df$Match), function(y) {
    ss <- df[df$Match==y,]
    
    home_kelly <- apply(as.matrix(ss[,c("H.P", "X.P", "A.P", "H.Odds")]), 1, function(x) kellyLogUtil(x[1], x[2], x[3], x[4]))
    
    away_kelly <- apply(as.matrix(ss[,c("A.P", "X.P", "H.P", "A.Odds")]), 1, function(x) kellyLogUtil(x[1], x[2], x[3], x[4]))
    
    data.frame(Match = y, H.Odds = ss$H.Odds, A.Odds = ss$A.Odds, H.Kelly = home_kelly, A.Kelly = away_kelly)
  }) %>%
    plyr::rbind.fill()
}


calcStakeDNB <- function(df, fraction = 0.25, bankroll = 10, minKelly = 20, minEdge = 0, minBet = 0.05, round = c("floor", "ceiling")) {
  
  roundmethod <- match.arg(round)
  
  # decide most appropriate picks
  df$Pick <- ifelse(df$H.Kelly > minKelly & df$H.Kelly - df$A.Kelly >= minEdge, "H",
                    ifelse(df$A.Kelly > minKelly & df$A.Kelly - df$H.Kelly >= minEdge, "A",
                           NA))
  
  # calculate stake
  df$Stake <- ifelse(df$Pick == "H", df$H.Kelly / 100 * fraction * bankroll,
                     ifelse(df$Pick == "A", df$A.Kelly / 100 * fraction * bankroll,
                            0))
  
  # round stake to unit
  if(roundmethod == "floor") {
    df$Stake <- minBet * floor(df$Stake / minBet)
  } else {
    df$Stake <- minBet * ceiling(df$Stake / minBet)
  }
  
  # estimated profit if pick wins
  df$Exp.Profit <- ifelse(df$Pick == "H", df$Stake * (df$H.Odds-1),
                          ifelse(df$Pick == "A", df$Stake * (df$A.Odds-1),
                                 0))
  df$Exp.Profit <- round(df$Exp.Profit, 2)
  
  df
}

validateKellyDNB <- function(df, summarise = FALSE) {
  
  # df <- left_join(stakes, results, by = "Match")
  
  df$Profit <- suppressWarnings(
    ifelse(df$Pick == "H" & df$Result == "H", df$Exp.Profit,
      ifelse(df$Pick == "H" & df$Result == "D", 0,
      ifelse(df$Pick == "H" & df$Result == "A", -df$Stake,
      ifelse(df$Pick == "A" & df$Result == "A", df$Exp.Profit,
      ifelse(df$Pick == "A" & df$Result == "D", 0,
      ifelse(df$Pick == "A" & df$Result == "H", -df$Stake, NA))))))
  )
  
  if(summarise) {
    sum(df$Profit, na.rm=T)
  } else {
    df %>%
      select(Match, H.Odds, A.Odds, Pick, Result, Profit) 
  }
}


vizKellyDNB <- function(df) {
  require(ggplot2)
  
  for(y in unique(df$Match)) {
    
    ss <- df[df$Match==y,]
    
    home <- kellyLogUtil(ss$H.P, ss$X.P, ss$A.P, ss$H.Odds, return_df = T)
    away <- kellyLogUtil(ss$A.P, ss$X.P, ss$H.P, ss$A.Odds, return_df = T)
  
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
      text(k_max - 10, min(home$k, na.rm=T) + (diff(range(home$k, na.rm=T) / 2)), paste0(k_max, "%"), cex = 1.5) 
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
    title(main = ss$Match, ylab = "f (x)", xlab = "Kelly Criterion (%)", outer = TRUE, line = 1)
  }
}
