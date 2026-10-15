# The meta-analysis of the time from symptom onset to death of Nash et al.
# (2024, Lancet Infect Dis; PMC7616620), figure 3C, redrawn with the outbreak
# and species of each estimate (from the review's data in the epireview
# package and the articles).
suppressMessages({library(ggplot2); library(patchwork)})
d <- read.table(header = TRUE, sep = "|", strip.white = TRUE, text = "
study            | outbreak                              | species    | mean  | sd   | n   | lo    | hi
Althaus 2015     | Nigeria 2014                          | Zaire      | 7.41  | 3.24 | 20  | 5.99  | 8.83
Aylward 2014     | Guinea, Liberia, Sierra Leone 2013-14 | Zaire      | 7.50  | 6.80 | 594 | 6.95  | 8.05
Faye 2015        | Guinea 2014                           | Zaire      | 8.90  | 4.00 | 82  | 8.03  | 9.77
Francesconi 2003 | Gulu, Uganda 2000                     | Sudan      | 9.64  | 3.46 | 15  | 7.89  | 11.39
Lanini 2015      | Freetown, Sierra Leone 2014-15        | Zaire      | 9.04  | 3.17 | 84  | 8.36  | 9.72
Muoghalu 2017    | Koinadugu, Sierra Leone 2014-15       | Zaire      | 6.70  | 4.10 | 27  | 5.15  | 8.25
Nanclares 2016   | Boende, DRC 2014                      | Zaire      | 9.89  | 3.92 | 25  | 8.36  | 11.43
Roddy 2012       | Bundibugyo, Uganda 2007               | Bundibugyo | 9.88  | 5.36 | 11  | 6.71  | 13.05
Rosello 2015     | Kikwit, DRC 1995                      | Zaire      | 9.47  | 4.44 | 317 | 8.98  | 9.96
Rosello 2015     | Mweka, DRC 2007-08                    | Zaire      | 7.62  | 4.44 | 32  | 6.08  | 9.16
Rosello 2015     | Isiro, DRC 2012                       | Bundibugyo | 11.37 | 5.41 | 52  | 9.90  | 12.84
Rosello 2015     | Boende, DRC 2014                      | Zaire      | 9.39  | 5.67 | 68  | 8.04  | 10.74
Schieffelin 2014 | Kenema, Sierra Leone 2014             | Zaire      | 9.79  | 4.32 | 38  | 8.42  | 11.16
Uyeki 2016       | Evacuated to US and Europe 2014-15    | Zaire      | 13.42 | 1.72 | 5   | 11.91 | 14.92
Wamala 2010      | Bundibugyo, Uganda 2007               | Bundibugyo | 10.50 | 4.19 | 39  | 9.19  | 11.82
Xu 2016          | Sierra Leone 2014-15                  | Zaire      | 8.60  | 4.80 | 76  | 7.52  | 9.68
")
d$outbreak <- gsub("-", "–", d$outbreak)
d$setting <- ifelse(grepl("Nigeria|Guinea|Sierra Leone|Evacuated", d$outbreak), "West Africa 2013–16",
                    ifelse(grepl("DRC", d$outbreak), "DRC", "Uganda"))
d <- d[order(factor(d$setting, c("West Africa 2013–16", "DRC", "Uganda")), -d$n), ]
d$row <- rev(seq_len(nrow(d))) + 1
pooled <- data.frame(row = 0, mean = 9.27, lo = 8.50, hi = 10.04)
cols <- c("West Africa 2013–16" = "#0072B2", "DRC" = "#E69F00", "Uganda" = "#009E73")
top <- max(d$row) + 1.2
txt <- function(x, label, data = d, ...) geom_text(data = data, aes(x = x, y = row, label = label), size = 3.6, ...)
cols_x <- c(study = 0, outbreak = 1.55, species = 4.55, mean = 5.75, sd = 6.35, n = 7.0)
heads <- data.frame(x = cols_x, row = top,
                    label = c("Study", "Outbreak", "Species", "Mean", "SD", "Patients"),
                    hj = c(0, 0, 0, 1, 1, 1))
table <- ggplot() +
  txt(cols_x["study"], d$study, hjust = 0) +
  geom_text(data = d, aes(x = cols_x["outbreak"], y = row, label = outbreak, colour = setting), size = 3.6, hjust = 0) +
  txt(cols_x["species"], d$species, hjust = 0) +
  txt(cols_x["mean"], sprintf("%.2f", d$mean), hjust = 1) +
  txt(cols_x["sd"], sprintf("%.2f", d$sd), hjust = 1) +
  txt(cols_x["n"], d$n, hjust = 1) +
  geom_text(data = heads, aes(x = x, y = row, label = label, hjust = hj), size = 3.8, fontface = "bold") +
  annotate("text", x = 0, y = 0, label = "Random effects, 16 estimates", hjust = 0, size = 3.6, fontface = "bold") +
  annotate("text", x = cols_x["mean"], y = 0, label = "9.27", hjust = 1, size = 3.6, fontface = "bold") +
  annotate("text", x = cols_x["n"], y = 0, label = "1,485", hjust = 1, size = 3.6, fontface = "bold") +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(limits = c(0, 7.1), expand = c(0, 0)) +
  scale_y_continuous(limits = c(-0.6, top + 0.4), expand = c(0, 0)) +
  theme_void()
diamond <- data.frame(x = c(pooled$lo, pooled$mean, pooled$hi, pooled$mean), y = c(0, 0.35, 0, -0.35))
forest <- ggplot(d, aes(y = row)) +
  geom_vline(xintercept = pooled$mean, linetype = "dashed", colour = "grey50") +
  geom_errorbarh(aes(xmin = lo, xmax = hi, colour = setting), height = 0) +
  geom_point(aes(x = mean, size = n, colour = setting), shape = 15) +
  geom_polygon(data = diamond, aes(x = x, y = y), fill = "grey40") +
  annotate("text", x = 10.5, y = top, label = "Mean and 95% CI (days)", size = 3.8, fontface = "bold") +
  scale_colour_manual(values = cols, name = NULL) +
  scale_size_area(max_size = 4, guide = "none") +
  scale_x_continuous(breaks = c(5, 8, 11, 14), limits = c(4.5, 16)) +
  scale_y_continuous(limits = c(-0.6, top + 0.4), expand = c(0, 0)) +
  labs(x = "Mean time from symptom onset to death (days)", y = NULL) +
  theme_minimal(base_size = 11) +
  theme(axis.text.y = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.minor = element_blank(), legend.position = "none")
g <- table + forest + plot_layout(widths = c(2.1, 1))
ggsave("outputs/bvd_onset_to_death_review.png", g, width = 12, height = 6.2, dpi = 200, bg = "white")
