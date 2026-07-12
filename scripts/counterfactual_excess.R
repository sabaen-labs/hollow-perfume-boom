#!/usr/bin/env Rscript
# Counterfactual "excess launches" = actual (2023-2025) minus the
# pre-disturbance trajectory. The baseline is a 4-parameter logistic (drc L.4)
# fitted on each series 1995-2022; predicting 2023-25 gives "what would have
# happened if the pre-existing saturation dynamics had held".
# Interrupted-time-series style: the identifying assumption is that the
# pre-2022 curve is a valid no-disturbance baseline (see fit_logistic.R for
# why the cut sits at 2022).
#
# Output: results/counterfactual_excess.csv (+ printed per-year and
# combined 2023-25 tables)

suppressWarnings(suppressMessages(library(drc)))
args <- commandArgs(trailingOnly = FALSE)
sp <- sub("^--file=", "", args[grep("^--file=", args)])
root <- if (length(sp)) normalizePath(file.path(dirname(sp), "..")) else normalizePath(".")

w <- read.csv(file.path(root, "data", "launches_by_year_combined.csv"),
              na.strings = c("NA", ""))
src <- c("Fragrantica" = "fragrantica", "Parfumo" = "parfumo", "Aromo" = "aromo")

rows <- list()
for (lab in names(src)) {
  d <- data.frame(year = w$year, n = w[[src[[lab]]]])
  d <- d[!is.na(d$n) & d$year >= 1995 & d$year <= 2025, ]
  train <- d[d$year <= 2022, ]
  m <- drm(n ~ year, data = train, fct = L.4())
  ceiling <- as.numeric(coef(m)["d:(Intercept)"])
  yrs <- 2023:2025
  cf <- as.numeric(predict(m, data.frame(year = yrs)))
  act <- sapply(yrs, function(y) d$n[d$year == y])
  for (i in seq_along(yrs)) {
    rows[[length(rows) + 1]] <- data.frame(
      source = lab, year = yrs[i], actual = round(act[i]),
      counterfactual = round(cf[i]), excess = round(act[i] - cf[i]),
      excess_pct = round(100 * (act[i] - cf[i]) / cf[i], 1),
      fitted_ceiling = round(ceiling))
  }
}
out <- do.call(rbind, rows)
write.csv(out, file.path(root, "results", "counterfactual_excess.csv"),
          row.names = FALSE)
cat("== Per-year excess vs pre-disturbance trajectory ==\n")
print(out, row.names = FALSE)

cat("\n== Cumulative 2023-2025 excess vs pre-disturbance trajectory ==\n")
agg <- aggregate(cbind(actual, counterfactual, excess) ~ source, out, sum)
agg$excess_pct_of_cf <- round(100 * agg$excess / agg$counterfactual, 1)
print(agg, row.names = FALSE)
