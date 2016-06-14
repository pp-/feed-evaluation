#!/usr/bin/Rscript --no-save --no-restore --no-init-file --no-environ

install_and_load <- function(pkg) {
  if (!pkg %in% installed.packages()[,"Package"]) {
    install.packages(pkg, repos = "https://cloud.r-project.org/")
  }
  if (!library(pkg, character.only = TRUE, warn.conflicts = FALSE, logical.return = TRUE)) {
    cat("\nFailed to load a required package:", pkg, "\n")
    cat("Perhaps consider installing it manually or update your R installation to the most recent version.\n\n")
    q(status = 1)
  }
}

install_and_load("circlize")
install_and_load("dplyr")



misp_data <- read.table("anonymized-overlap-data-2015-07--2016-06.csv",
           sep="\t",
           na.strings = "\\N",
           header = F,
           col.names = c("source1", "source2", "ip"),
           colClasses = c("factor", "factor", "character")
           )

misp_linkage <- misp_data %>%
  filter(!is.na(source2)) %>%
  group_by(source1, source2) %>%
  summarize(count=n())

SMALL_SOURCE_THRESHOLD = 1000 # Adjust this value, set to zero to display all
small_sources <- (misp_linkage %>%
                    group_by(source2) %>%
                    summarize(total_count=sum(count)) %>%
                    filter(total_count < SMALL_SOURCE_THRESHOLD)
                  )$source2

misp_linkage_simplified <- misp_linkage %>%
  mutate(source2_simplified = ifelse(as.character(source2) %in% small_sources, "OTHER", as.character(source2))) %>%
  group_by(source1, source2_simplified) %>%
  summarize(count=sum(count))

misp_colors_labels <- as.vector(unique(misp_linkage_simplified$source2_simplified))
misp_colors <- rep("#e78ac3", length(misp_colors_labels))
names(misp_colors) <- misp_colors_labels
misp_colors["circl-lu.misp"] <- "#66c2a5"
misp_colors["a.misp"] <- "#8da0cb"
misp_colors["b.misp"] <- "#fc8d62"

OUTPUT_PLOT_FILE <- "output-diagram.pdf"
cat("Saving output diagram to:", OUTPUT_PLOT_FILE, "\n")
cairo_pdf(filename = OUTPUT_PLOT_FILE, width = 8, height = 8)

circos.clear()
circos.par(start.degree = 280, gap.degree = 3, track.margin = c(-0.1, 0.1))
chordDiagram(misp_linkage_simplified,
             grid.col = misp_colors,
             annotationTrack = "grid",
             preAllocateTracks=list(track.height=0.5),
             directional = 1,
             direction.type = c("arrows", "diffHeight"),
             diffHeight = -0.02,
             link.arr.type = "big.arrow",
             link.sort = TRUE,
             link.largest.ontop = TRUE,
             transparency = 0.3
)
circos.trackPlotRegion(track.index=1, panel.fun=function(x,y){
  xlim=get.cell.meta.data("xlim")
  ylim=get.cell.meta.data("ylim")
  sector.name=get.cell.meta.data("sector.index")
  circos.text(mean(xlim), 0, sector.name, facing="clockwise", niceFacing=T, adj=c(0,0.5))
}, bg.border=NA)

misp_stats_counts <- misp_data %>% group_by(source1) %>% summarize(n_ip = n_distinct(ip), uniq_to_source = sum(is.na(source2))) %>% mutate(overlap_ratio = 1- uniq_to_source / n_ip)

misp_stats_overlap_with_other <- misp_data %>%
  filter(!source2 %in% c("a.misp", "b.misp", "circl-lu.misp") & !is.na(source2)) %>%
  group_by(source1) %>%
  summarize(n_in_other = n_distinct(ip))

misp_stats_overlap_with_misps <- misp_data %>%
  filter(source2 %in% c("a.misp", "b.misp", "circl-lu.misp")) %>%
  group_by(source1) %>%
  summarize(n_in_misps = n_distinct(ip))

misp_stats_joined <-
  full_join(misp_stats_counts, misp_stats_overlap_with_other, by = "source1") %>%
  mutate(ratio_other = n_in_other / n_ip) %>%
  full_join(misp_stats_overlap_with_misps, by = "source1") %>%
  mutate(ratio_misps = n_in_misps / n_ip) %>%
  select(source1, n_ip, overlap_ratio, ratio_misps, ratio_other)

OUTPUT_CSV_FILE <- "output-stats.csv"
cat("Saving overlap statistics to:", OUTPUT_CSV_FILE, "\n")
write.table(misp_stats_joined, file = OUTPUT_CSV_FILE, quote = FALSE,
            sep = "\t", row.names = FALSE
)
