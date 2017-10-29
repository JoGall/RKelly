# Optimise minimum full Kelly percentage and minimum edge (difference between full Kelly bets for home and away) in Draw No Bet stake optimisation by maximising profits using historical data
# NOTE: Still haven't decided if 'edge' is bullshit or not; minimum probability or maximum difference in probability might be more appropriate

# get sample data
kelly1 <- read.csv("~/Dropbox/github/RKelly/DATA/kelly/2017-10-21_kelly.csv")
kelly2 <- read.csv("~/Dropbox/github/RKelly/DATA/kelly/2017-10-28_kelly.csv")
results1 <- read.csv("~/Dropbox/github/RKelly/DATA/results/2017-10-21_results.csv")
results2 <- read.csv("~/Dropbox/github/RKelly/DATA/results/2017-10-28_results.csv")
d1 <- left_join(kelly1, results1, by = "Match")
d2 <- left_join(kelly2, results2, by = "Match")
List <- list(d1, d2)

# optimise minKelly variable
optKelly <- lapply(1:length(List), function(x) {
  ss <- List[[x]]
  lapply(-99:99, function(y) {
    picks <- calcStakeDNB(ss, minKelly = y, minEdge = 0)
    profit <- validateKellyDNB(picks)
    data.frame(day = x, minKelly = y, profit = sum(profit$Profit, na.rm=T))
  }) %>%
    plyr::rbind.fill()
}) %>%
  plyr::rbind.fill()

ggplot() +
  geom_line(data = optKelly, aes(x = minKelly, y = profit, group = day), col="grey50") +
  geom_line(data = optKelly %>% group_by(minKelly) %>% summarise(profit = mean(profit)), aes(x = minKelly, y = profit), col="red", lwd = 1.2) +
  geom_hline(yintercept = 0, lty = 3)

# optimise minEdge variable
optEdge <- lapply(1:length(List), function(x) {
  ss <- List[[x]]
  lapply(0:50, function(y) {
    picks <- calcStakeDNB(ss, minKelly = 10, minEdge = y)
    profit <- validateKellyDNB(picks, results = F)
    data.frame(day = x, minEdge = y, profit = sum(profit$Profit, na.rm=T))
  }) %>%
    plyr::rbind.fill()
}) %>%
  plyr::rbind.fill()

ggplot(optEdge, aes(x = minEdge, y = profit, group = day)) +
  geom_line() +
  # geom_smooth(se = F) +
  geom_hline(yintercept = 0, lty = 3)


# optimise both minKelly and minEdge variables
optBoth <- lapply(1:length(List), function(x) {
  ss <- List[[x]]
  lapply(seq(-100, 100, 5), function(y) {
    lapply(seq(0, 100, 5), function(z) {
      picks <- calcStakeDNB(ss, minKelly = y, minEdge = z)
      profit <- validateKellyDNB(picks, results = F)
      data.frame(day = x, minKelly = y, minEdge = z, profit = sum(profit$Profit, na.rm=T))
    }) %>%
      plyr::rbind.fill()
  }) %>%
    plyr::rbind.fill()
}) %>%
  plyr::rbind.fill()

# heatmap of both variables
ggplot(optBoth, aes(x = minKelly, y = minEdge, group = day)) +
  geom_tile(data = optBoth, aes(fill = profit), size = 2.5) + 
  # scale_fill_gradient(low = "white", high = "red") +
  scale_fill_gradientn(colours = c("blue", "white", "red"), limits = c(-5, 5)) +
  geom_hline(yintercept = 0, lty = 3) +
  theme_bw()
