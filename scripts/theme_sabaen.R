# SABAEN house style for analytical figures.
# Minimalist, Tufte-inspired: small multiples, dotted y-grid, no axis lines,
# charcoal data ink, gold reserved for the story accent. Palette is
# CVD-validated (adjacent-pair dE ~50); light golds fail 3:1 contrast on the
# paper for thin marks - use GOLD_DEEP for marks, GOLD only for fills/shading.

suppressWarnings(suppressMessages({
  library(ggplot2); library(sysfonts); library(showtext)
}))

# ---- brand tokens ----
SABAEN_PAPER       <- "#f5f5f0"  # background
SABAEN_INK         <- "#1a1a1a"  # data lines, primary text
SABAEN_INK_MUTED   <- "#6e6e66"  # secondary text, tick labels
SABAEN_FOREST_DEEP <- "#1e3a2f"  # series colour (overlays)
SABAEN_FOREST_MED  <- "#2d4f3f"  # model/reference lines
SABAEN_GOLD        <- "#c9a962"  # fills and shading ONLY (2.1:1 on paper)
SABAEN_GOLD_DEEP   <- "#9a7f4e"  # accent marks + accent text
SABAEN_SAGE        <- "#6f8a7d"  # derived tint (third series if unavoidable)
SABAEN_GRID        <- "#dcdcd2"  # dotted gridlines

# ---- typography: Cormorant Garamond (titles) + Inter (everything else) ----
# Falls back to Georgia/Helvetica when Google Fonts are unreachable.
sabaen_fonts <- function() {
  serif_ok <- tryCatch({ font_add_google("Cormorant Garamond", "cormorant",
                                         regular.wt = 500, bold.wt = 600); TRUE },
                       error = function(e) FALSE)
  sans_ok  <- tryCatch({ font_add_google("Inter", "inter",
                                         regular.wt = 400, bold.wt = 600); TRUE },
                       error = function(e) FALSE)
  showtext_auto(); showtext_opts(dpi = 300)
  list(serif = if (serif_ok) "cormorant" else "Georgia",
       sans  = if (sans_ok)  "inter"     else "Helvetica")
}

# ---- the theme ----
# Sentence-case titles; no legend boxes (direct labels / facet strips carry
# identity); dotted y-grid only; no axis lines; x ticks only.
theme_sabaen <- function(base_size = 10, fonts = sabaen_fonts()) {
  theme_minimal(base_size = base_size, base_family = fonts$sans) +
    theme(
      plot.background    = element_rect(fill = SABAEN_PAPER, colour = NA),
      panel.background   = element_rect(fill = SABAEN_PAPER, colour = NA),
      panel.grid         = element_blank(),
      panel.grid.major.y = element_line(colour = SABAEN_GRID,
                                        linetype = "dotted", linewidth = 0.35),
      axis.line          = element_blank(),
      axis.ticks.y       = element_blank(),
      axis.ticks.x       = element_line(colour = SABAEN_INK, linewidth = 0.3),
      axis.ticks.length  = unit(3, "pt"),
      axis.text          = element_text(colour = SABAEN_INK_MUTED, size = 8),
      axis.title         = element_blank(),
      legend.position    = "none",
      strip.text         = element_text(colour = SABAEN_INK, size = 10,
                                        family = fonts$sans, face = "bold",
                                        hjust = 0, margin = margin(b = 6)),
      plot.title    = element_text(family = fonts$serif, size = 19,
                                   colour = SABAEN_INK, margin = margin(b = 3)),
      plot.subtitle = element_text(colour = SABAEN_INK_MUTED, size = 9.5,
                                   lineheight = 1.15, margin = margin(b = 14)),
      plot.caption  = element_text(colour = SABAEN_INK_MUTED, size = 7.5,
                                   hjust = 0, lineheight = 1.25,
                                   margin = margin(t = 12)),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      plot.margin   = margin(16, 20, 12, 16),
      panel.spacing = unit(22, "pt")
    )
}

# Standard footer: brand mark + source(s) + any method note.
sabaen_caption <- function(sources, note = NULL) {
  label <- if (grepl(",", sources)) "Sources" else "Source"
  paste(c(paste0("SABAEN  ·  ", label, ": ", sources), note),
        collapse = "  ·  ")
}
