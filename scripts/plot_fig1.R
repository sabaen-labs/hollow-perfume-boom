# Figure 1: three launch series, pre-2022 logistic fits, and the 2023-25
# break above trend; dashed counterfactual continued to 2030.
# SABAEN house style (scripts/theme_sabaen.R).
# The fit window is 1995-2022; 2023-25 is out of sample (see fit_logistic.R
# for why the cut sits at 2022).
# Run from repo root:  Rscript scripts/plot_fig1.R

suppressWarnings(suppressMessages({ library(drc); library(ragg) }))

args <- commandArgs(trailingOnly = FALSE)
sp   <- sub("^--file=", "", args[grep("^--file=", args)])
root <- if (length(sp)) normalizePath(file.path(dirname(sp), "..")) else normalizePath(".")
source(file.path(root, "scripts", "theme_sabaen.R"))
FONTS <- sabaen_fonts()

# ---- data + fits (fit window: 1995-2022; 2023-25 out of sample) ----
w <- read.csv(file.path(root, "data", "launches_by_year_combined.csv"),
              na.strings = c("NA", ""))
src    <- c("Fragrantica" = "fragrantica", "Parfumo" = "parfumo", "Aromo" = "aromo")
excess <- c("Fragrantica" = "+30%", "Parfumo" = "+61%", "Aromo" = "+69%")  # 2023-25 combined

pts <- list(); fits <- list()
for (lab in names(src)) {
  d <- data.frame(year = w$year, n = w[[src[[lab]]]], source = lab)
  d <- d[!is.na(d$n) & d$year >= 1995 & d$year <= 2025, ]
  m <- drm(n ~ year, data = d[d$year <= 2022, ], fct = L.4())
  g <- data.frame(year = seq(1995, 2030, by = 0.1))
  g$n <- as.numeric(predict(m, g)); g$source <- lab
  g$window <- ifelse(g$year <= 2022, "fit", "counterfactual")
  pts[[lab]] <- d; fits[[lab]] <- g
}
pts  <- do.call(rbind, pts);  fits <- do.call(rbind, fits)
pts$source  <- factor(pts$source,  levels = names(src))
fits$source <- factor(fits$source, levels = names(src))
brk <- pts[pts$year >= 2023, ]

ann <- data.frame(source = factor(names(src), levels = names(src)),
                  x = 2020.3,
                  y = sapply(names(src), function(l) max(pts$n[pts$source == l])),
                  lab = paste0(excess[names(src)], "\nvs trend"))

kfmt <- function(x) ifelse(x >= 1000, paste0(x / 1000, "k"), x)

# ---- figure ----
fig1 <- ggplot() +
  geom_line(data = fits[fits$window == "fit", ],
            aes(year, n, group = source),
            colour = SABAEN_FOREST_MED, alpha = 0.55, linewidth = 0.5) +
  geom_line(data = fits[fits$window == "counterfactual", ],
            aes(year, n, group = source),
            colour = SABAEN_FOREST_MED, alpha = 0.55, linetype = "21",
            linewidth = 0.5) +
  geom_line(data = pts, aes(year, n), colour = SABAEN_INK, linewidth = 0.45) +
  geom_point(data = brk, aes(year, n),
             fill = SABAEN_GOLD_DEEP, colour = SABAEN_PAPER, shape = 21,
             size = 2.3, stroke = 0.5) +
  geom_text(data = ann, aes(x, y, label = lab),
            family = FONTS$sans, fontface = "bold", colour = SABAEN_GOLD_DEEP,
            size = 2.9, hjust = 1, vjust = 0.9, lineheight = 0.95) +
  facet_wrap(~source, nrow = 1) +
  scale_x_continuous(breaks = c(2000, 2010, 2020, 2030)) +
  scale_y_continuous(labels = kfmt, breaks = seq(0, 16000, 4000),
                     limits = c(0, 16500), expand = c(0, 0)) +
  labs(title = "Straight through the ceiling",
       subtitle = paste0("New fragrance launches per year. The trajectory in ",
                         "each database pointed to a plateau;\n2023–25 broke ",
                         "above it."),
       caption = sabaen_caption("Fragrantica, Parfumo, Aromo",
                                paste0("Curves fitted on 1995–2022 (green); ",
                                       "dashed = that trajectory, continued"))) +
  theme_sabaen(fonts = FONTS)

out <- file.path(root, "results", "fig1_three_series_break.png")
agg_png(out, width = 2184, height = 1150, units = "px", res = 300,
        background = SABAEN_PAPER)
print(fig1); invisible(dev.off())
cat("written:", out, "\n")
