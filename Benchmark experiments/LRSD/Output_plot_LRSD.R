rm(list=ls())
setwd(file.path(getwd()))
# ------------------------------------------------------------
# load libraries
# ------------------------------------------------------------

if (!requireNamespace("tidyverse", quietly = TRUE)) {
  install.packages("tidyverse")
}
library(tidyverse)

if (!requireNamespace("ggh4x", quietly = TRUE)) {
  install.packages("ggh4x")
}
library(ggh4x)


if (!requireNamespace("ggtext", quietly = TRUE)) {
  install.packages("ggtext")
}
library(ggtext)


# ------------------------------------------------------------
# MAE L
# ------------------------------------------------------------


# ------------------------------------------------------------
# Load rank 5 and 10 funvals data
# ------------------------------------------------------------

MAE_L_50_10_5<-read.csv("Outputs/All_funvals_MAE_L_n_50_p_10_d_5_reps_10.csv", header=FALSE, 
                        col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))
MAE_L_70_20_5<-read.csv("Outputs/All_funvals_MAE_L_n_70_p_20_d_5_reps_10.csv", header=FALSE, 
                        col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))
MAE_L_100_50_5<-read.csv("Outputs/All_funvals_MAE_L_n_100_p_50_d_5_reps_10.csv", header=FALSE, 
                         col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))
MAE_L_100_100_5<-read.csv("Outputs/All_funvals_MAE_L_n_100_p_100_d_5_reps_10.csv", header=FALSE, 
                          col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))


MAE_L_50_10_5_subset <- MAE_L_50_10_5[, !(names(MAE_L_50_10_5) %in% c("BOOOM"))]
MAE_L_70_20_5_subset <- MAE_L_70_20_5[, !(names(MAE_L_70_20_5) %in% c("BOOOM"))]
MAE_L_100_50_5_subset <- MAE_L_100_50_5[, !(names(MAE_L_100_50_5) %in% c("BOOOM"))]
MAE_L_100_100_5_subset <- MAE_L_100_100_5[, !(names(MAE_L_100_100_5) %in% c("BOOOM"))]



MAE_L_50_10_5_subset_long <- pivot_longer(data = MAE_L_50_10_5_subset, cols = c("BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"),
                                          names_to = "Methods", values_to = "MAE") %>% 
  mutate(Methods = fct_relevel( factor(Methods), "BOOOM_Parallel", "AccAlt_projection", "GoDec_plus", "LRSD_TNNSR")) %>%
  mutate(dimension = "A",rank="rank 5")

MAE_L_70_20_5_subset_long <- pivot_longer(data = MAE_L_70_20_5_subset, cols = c("BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"),
                                          names_to = "Methods", values_to = "MAE") %>% 
  mutate(Methods = fct_relevel( factor(Methods), "BOOOM_Parallel", "AccAlt_projection", "GoDec_plus", "LRSD_TNNSR")) %>% 
  mutate(dimension = "B",rank="rank 5")

MAE_L_100_50_5_subset_long <- pivot_longer(data = MAE_L_100_50_5_subset, cols = c("BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"),
                                           names_to = "Methods", values_to = "MAE") %>% 
  mutate(Methods = fct_relevel( factor(Methods), "BOOOM_Parallel", "AccAlt_projection", "GoDec_plus", "LRSD_TNNSR")) %>% 
  mutate(dimension = "C",rank="rank 5")

MAE_L_100_100_5_subset_long <- pivot_longer(data = MAE_L_100_100_5_subset, cols = c("BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"),
                                            names_to = "Methods", values_to = "MAE") %>% 
  mutate(Methods = fct_relevel( factor(Methods), "BOOOM_Parallel", "AccAlt_projection", "GoDec_plus", "LRSD_TNNSR")) %>%
  mutate(dimension = "D",rank="rank 5")


MAE_L_50_10_10<-read.csv("Outputs/All_funvals_MAE_L_n_50_p_10_d_10_reps_10.csv", header=FALSE, 
                         col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))
MAE_L_70_20_10<-read.csv("Outputs/All_funvals_MAE_L_n_70_p_20_d_10_reps_10.csv", header=FALSE, 
                         col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))
MAE_L_100_50_10<-read.csv("Outputs/All_funvals_MAE_L_n_100_p_50_d_10_reps_10.csv", header=FALSE, 
                          col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))
MAE_L_100_100_10<-read.csv("Outputs/All_funvals_MAE_L_n_100_p_100_d_10_reps_10.csv", header=FALSE, 
                           col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))

MAE_L_50_10_10_subset <- MAE_L_50_10_10[, !(names(MAE_L_50_10_10) %in% c("BOOOM"))]
MAE_L_70_20_10_subset <- MAE_L_70_20_10[, !(names(MAE_L_70_20_10) %in% c("BOOOM"))]
MAE_L_100_50_10_subset <- MAE_L_100_50_10[, !(names(MAE_L_100_50_10) %in% c("BOOOM"))]
MAE_L_100_100_10_subset <- MAE_L_100_100_10[, !(names(MAE_L_100_100_10) %in% c("BOOOM"))]




MAE_L_50_10_10_subset_long <- pivot_longer(data = MAE_L_50_10_10_subset, cols = c("BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"),
                                           names_to = "Methods", values_to = "MAE") %>% 
  mutate(Methods = fct_relevel( factor(Methods), "BOOOM_Parallel", "AccAlt_projection", "GoDec_plus", "LRSD_TNNSR")) %>%
  mutate(dimension = "A",rank="rank 10")

MAE_L_70_20_10_subset_long <- pivot_longer(data = MAE_L_70_20_10_subset, cols = c("BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"),
                                           names_to = "Methods", values_to = "MAE") %>% 
  mutate(Methods = fct_relevel( factor(Methods), "BOOOM_Parallel", "AccAlt_projection", "GoDec_plus", "LRSD_TNNSR")) %>% 
  mutate(dimension = "B",rank="rank 10")


MAE_L_100_50_10_subset_long <- pivot_longer(data = MAE_L_100_50_10_subset, cols = c("BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"),
                                            names_to = "Methods", values_to = "MAE") %>% 
  mutate(Methods = fct_relevel( factor(Methods), "BOOOM_Parallel", "AccAlt_projection", "GoDec_plus", "LRSD_TNNSR")) %>% 
  mutate(dimension = "C",rank="rank 10")

MAE_L_100_100_10_subset_long <- pivot_longer(data = MAE_L_100_100_10_subset, cols = c("BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"),
                                             names_to = "Methods", values_to = "MAE") %>% 
  mutate(Methods = fct_relevel( factor(Methods), "BOOOM_Parallel", "AccAlt_projection", "GoDec_plus", "LRSD_TNNSR")) %>%
  mutate(dimension = "D",rank="rank 10")


# ------------------------------------------------------------
# Combine all scenarios
# ------------------------------------------------------------

final_data <- rbind(
  MAE_L_50_10_5_subset_long,
  MAE_L_70_20_5_subset_long,
  MAE_L_100_50_5_subset_long,
  MAE_L_100_100_5_subset_long,
  MAE_L_50_10_10_subset_long,
  MAE_L_70_20_10_subset_long,
  MAE_L_100_50_10_subset_long,
  MAE_L_100_100_10_subset_long
)

final_data$rank <- factor(final_data$rank, levels = c("rank 5","rank 10"))

# ------------------------------------------------------------
# Clean labels
# ------------------------------------------------------------

final_data$dimension <- recode(final_data$dimension,
                               "A"="n = 50, p = 10",
                               "B"="n = 70, p = 20",
                               "C"="n = 100, p = 50",
                               "D"="n = 100, p = 100")

final_data$dimension <- factor(
  final_data$dimension,
  levels = c(
    "n = 50, p = 10",
    "n = 70, p = 20",
    "n = 100, p = 50",
    "n = 100, p = 100"
  )
)

final_data$Methods <- recode(final_data$Methods,
                             "BOOOM_Parallel"="BOOOM",
                             "AccAlt_projection"="AccAltProj",
                             "GoDec_plus"="GoDec+",
                             "LRSD_TNNSR"="LRSD-TNNSR")

final_data$Methods <- factor(final_data$Methods,
                             levels=c("BOOOM","AccAltProj","GoDec+","LRSD-TNNSR"))

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

method_colors <- c(
  "BOOOM"       = "#E64B35",
  "AccAltProj"  = "#7CAE00",
  "GoDec+"      = "#00BFC4",
  "LRSD-TNNSR"  = "#C77CFF"
)

# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------

p1 <- ggplot(final_data,
             aes(x = Methods, y = MAE, fill = Methods)) +
  
  geom_boxplot(width = .65,
               outlier.size = 1.5,
               colour = "black") +
  
  scale_y_log10() +
  
  facet_wrap(~ rank + dimension,
             nrow = 2,
             scales = "free_y") +
  
  scale_fill_manual(values = method_colors) +
  
  labs(
    x = NULL,
    y = "MAE"
  ) +
  
  theme_bw(base_size = 18) +
  theme(
    legend.position = "top",
    legend.title = element_blank(),
    
    legend.text = element_text(size = 18),
    legend.key.size = unit(1.3,"cm"),
    
    strip.background = element_rect(fill = "grey92",
                                    colour = "grey40"),
    
    strip.text = element_text(size = 16, face = "bold"),
    
    axis.text.x = element_text(size = 13, angle = 20, hjust = 1),
    
    panel.grid.major = element_line(colour = "grey90"),
    panel.grid.minor = element_blank(),
    
    panel.spacing.y = unit(1.6, "lines"),
    panel.spacing.x = unit(0.8, "lines")
  )

# ------------------------------------------------------------
# Save
# ------------------------------------------------------------

ggsave(
  "Boxplots_LRSD.png",
  p1,
  width = 16,
  height = 8.5,
  dpi = 400
)