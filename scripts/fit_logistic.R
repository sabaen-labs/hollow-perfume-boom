#!/usr/bin/env Rscript
# Fit a 4-parameter logistic (drc L.4) to each launch series on the
# pre-disturbance window 1995-2022 and report the parameters quoted in the
# article: fitted ceiling (with standard error), inflection year, the year the
# curve reaches 95% of its ceiling, and R-squared.
#
# The baseline cut is 2022: 2023 already shows the disturbance (+18% YoY on
# Parfumo/Aromo against a +8.5-10% norm for the preceding years), and 2023 is
# the first full year after the 2020-22 rollout of algorithmic recommendation
# feeds on the major discovery platforms.
#
# Output: results/logistic_fit_parameters.csv (+ printed table)

suppressWarnings(suppressMessages(library(drc)))
args <- commandArgs(trailingOnly = FALSE)
sp <- sub("^--file=", "", args[grep("^--file=", args)])
root <- if (length(sp)) normalizePath(file.path(dirname(sp), "..")) else normalizePath(".")

ORIGIN <- 2000L; ctl <- drmc(maxIt = 2000, relTol = 1e-10, errorm = FALSE)

w <- read.csv(file.path(root, "data", "launches_by_year_combined.csv"),
              na.strings = c("NA", ""))
src <- c("Fragrantica" = "fragrantica", "Parfumo" = "parfumo", "Aromo" = "aromo")

rows <- list()
for (lab in names(src)) {
  d <- data.frame(year = w$year, n = w[[src[[lab]]]])
  d <- d[!is.na(d$n) & d$year >= 1995 & d$year <= 2022, ]
  d$t <- d$year - ORIGIN
  m <- drm(n ~ t, data = d, fct = L.4(), control = ctl)
  co <- summary(m)$coefficients
  d0  <- co["d:(Intercept)", 1]   # upper asymptote (ceiling)
  dse <- co["d:(Intercept)", 2]
  e0  <- co["e:(Intercept)", 1]   # inflection point
  ed  <- tryCatch(ED(m, 95, interval = "delta", display = FALSE),
                  error = function(x) matrix(NA, 1, 4))
  r2 <- 1 - sum(residuals(m)^2) / sum((d$n - mean(d$n))^2)
  rows[[length(rows) + 1]] <- data.frame(
    source = lab, fit_window = "1995-2022",
    ceiling = round(d0), ceiling_se = round(dse),
    ceiling_se_pct = round(100 * dse / d0, 1),
    inflection_year = round(e0 + ORIGIN, 1),
    sat95_year = round(ed[1] + ORIGIN, 1),
    r2 = round(r2, 4))
}
out <- do.call(rbind, rows)
write.csv(out, file.path(root, "results", "logistic_fit_parameters.csv"),
          row.names = FALSE)
cat("4-parameter logistic per series, fitted on 1995-2022\n\n")
print(out, row.names = FALSE)
