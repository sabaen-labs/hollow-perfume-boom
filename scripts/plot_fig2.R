# Figure 2: top brand movers behind the 2023->2025 jump, as a dumbbell chart
# (open dot = launches/yr in 2023, filled dot = 2025), so "started from
# almost nothing" is visible structure: gold dumbbells pinned at zero.
# SABAEN house style (scripts/theme_sabaen.R).
#
# Data note: the brand table records the ~150 most prolific brands in each
# year, so a value of 0 means "below that threshold" (fewer than a dozen
# launches in 2023), never "no launches at all".
# Run from repo root:  Rscript scripts/plot_fig2.R

suppressWarnings(suppressMessages({ library(ggplot2); library(ragg) }))

args <- commandArgs(trailingOnly = FALSE)
sp   <- sub("^--file=", "", args[grep("^--file=", args)])
root <- if (length(sp)) normalizePath(file.path(dirname(sp), "..")) else normalizePath(".")
source(file.path(root, "scripts", "theme_sabaen.R"))
FONTS <- sabaen_fonts()

br <- read.csv(file.path(root, "data", "driver_top_brands.csv"))
names(br)[1] <- "brand"
br <- head(br[order(-br$growth_23_25), ], 20)
br$kind <- ifelse(br$y2023 == 0, "zero", "expanding")
# tag the first row of each kind in place of a legend box
first_zero <- which(br$kind == "zero")[1]; first_exp <- which(br$kind == "expanding")[1]
br$tag <- ""
br$tag[first_zero] <- "fewer than a dozen in 2023"
br$tag[first_exp]  <- "already established in 2023"
br$brand <- factor(br$brand, levels = rev(br$brand))

# sanity print: how much of the Fragrantica jump do these 20 explain?
w <- read.csv(file.path(root, "data", "launches_by_year_combined.csv"),
              na.strings = c("NA", ""))
jump <- w$fragrantica[w$year == 2025] - w$fragrantica[w$year == 2023]
cat(sprintf("top-20 movers sum: +%d launches/yr (FR 2023->2025 jump = +%d => %.0f%%)\n",
            sum(br$growth_23_25), jump, 100 * sum(br$growth_23_25) / jump))

kpal <- c("zero" = SABAEN_GOLD_DEEP, "expanding" = SABAEN_FOREST_MED)

fig2 <- ggplot(br) +
  geom_segment(aes(x = y2023, xend = y2025, y = brand, yend = brand,
                   colour = kind), linewidth = 0.55) +
  geom_point(aes(y2023, brand, colour = kind), shape = 21, fill = SABAEN_PAPER,
             size = 2, stroke = 0.6) +
  geom_point(aes(y2025, brand, colour = kind), size = 2.4) +
  geom_text(aes(y2025 + 4, brand, label = sprintf("%d", as.integer(y2025))),
            hjust = 0, family = FONTS$sans, size = 2.7,
            colour = SABAEN_INK_MUTED) +
  geom_text(aes(y2025 + 16, brand, label = tag, colour = kind), hjust = 0,
            family = FONTS$sans, fontface = "bold", size = 2.7) +
  scale_colour_manual(values = kpal) +
  scale_x_continuous(expand = expansion(mult = c(0.01, 0.14))) +
  labs(title = "The wave has names",
       subtitle = paste0("Launches per year in 2023 (open) and 2025 (filled) for ",
                         "the twenty brands that added the most.\nOrdered by ",
                         "launches added; brands shown at zero in 2023 had fewer ",
                         "than a dozen launches that year."),
       caption = paste0(sabaen_caption("Fragrantica"),
                        "\nThese twenty explain about a quarter of the 2023–2025 ",
                        "jump; the rest is a long tail of hundreds of small houses.")) +
  theme_sabaen(fonts = FONTS) +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = SABAEN_GRID,
                                          linetype = "dotted", linewidth = 0.35),
        axis.text.y = element_text(colour = SABAEN_INK, size = 8.2),
        axis.ticks.x = element_blank())

out <- file.path(root, "results", "fig2_top_brand_movers.png")
agg_png(out, width = 2184, height = 1560, units = "px", res = 300,
        background = SABAEN_PAPER)
print(fig2); invisible(dev.off())
cat("written:", out, "\n")
