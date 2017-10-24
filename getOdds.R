require(XML)
require(RCurl)

getOdds <- function(URLs) {
  
  # get matches and H-X-A odds
  print("Getting H-X-A markets...")

  odds <- lapply(urls, function(x) {
    
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
  
  # keep matches played today
  odds <- odds[grep("Today", odds$KO),]
  
  # get DNB odds for each match
  print("Getting Draw No Bet markets...")
  odds2 <- lapply(1:nrow(odds), function(x) {
   
    print(paste0(x, " / ", nrow(odds)))
    Sys.sleep(runif(1, 1, 2))
    url <- odds$href[x]
    
    doc <- htmlParse(url)
    
    dnb_odds <- xpathSApply(doc, "//*[starts-with(@class,'two-col-market ev-layout ev-layout-disporder_33')]//span[@class='odds-decimal']", xmlValue, trim=TRUE)
    
    data.frame(odds[x,], DNB.H.Odds = as.numeric(as.character(dnb_odds[1])), DNB.A.Odds = as.numeric(as.character(dnb_odds[2]))) %>%
      select(-KO, -href)
  }) %>%
    plyr::rbind.fill()
    
  return(odds2)
}