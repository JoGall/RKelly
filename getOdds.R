require(XML)
require(RCurl)
require(dplyr)

getOdds1X2 <- function(URLs, href = TRUE) {
  
  lapply(URLs, function(x) {
    
    print(x)
    Sys.sleep(runif(1, 1, 2))
    
    doc <- htmlParse(x)
    
    matches <- xpathSApply(doc, "//div[@class='match featured-match']//div[@class='bet-title']", xmlValue, trim = TRUE)
    datetimes <- xpathSApply(doc, "//div[@class='date-time bs-tooltip-trigger']", xmlValue, trim = TRUE) %>%
      sub("\n.*", "", .)
    hrefs <- xpathSApply(doc, "//div[@class='bet-title']//a", xmlGetAttr, 'href')
    hodds <- xpathSApply(doc, "//div[@class='home-odds']//span[@class='odds-decimal']", xmlValue, trim = TRUE)
    xodds <- xpathSApply(doc, "//div[@class='draw-odds']//span[@class='odds-decimal']", xmlValue, trim = TRUE)
    aodds <- xpathSApply(doc, "//div[@class='away-odds']//span[@class='odds-decimal']", xmlValue, trim = TRUE)
    
    data.frame(Match = matches, KO = datetimes, H.Odds = as.numeric(as.character(hodds)), X.Odds = as.numeric(as.character(xodds)), A.Odds = as.numeric(as.character(aodds)), href = hrefs)
  }) %>%
    plyr::rbind.fill()
}
  
getOddsDNB <- function(odds) {
  
  lapply(1:nrow(odds), function(x) {
   
    print(paste0(x, "/", nrow(odds), ": ", odds$Match[x]))
    Sys.sleep(runif(1, 1, 2))
    url <- odds$href[x]
    
    doc <- htmlParse(url)
    
    dnb_odds <- xpathSApply(doc, "//*[starts-with(@class,'two-col-market ev-layout ev-layout-disporder_33')]//span[@class='odds-decimal']", xmlValue, trim=TRUE)
    if(length(dnb_odds>0)) {
      dnb.h.odds <- as.numeric(as.character(dnb_odds[1]))
      dnb.a.odds <- as.numeric(as.character(dnb_odds[2]))
    } else {
      dnb.h.odds <- NA
      dnb.a.odds <- NA
    }
    
    data.frame(odds[x,], DNB.H.Odds = dnb.h.odds, DNB.A.Odds = dnb.a.odds) %>%
      select(-KO, -href)
  }) %>%
    plyr::rbind.fill()
}
