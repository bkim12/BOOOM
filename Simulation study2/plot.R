rm(list=ls())

# load libraries
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

# set working directory
setwd("Simulation result")


########
###################################
###################################
## L
### MAE L

#############################################################################################################
## rank 5


MAE_L_50_10_5<-read.csv("All_funvals_MAE_L_n_50_p_10_d_5_reps_10.csv", header=FALSE, 
                        col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))
MAE_L_70_20_5<-read.csv("All_funvals_MAE_L_n_70_p_20_d_5_reps_10.csv", header=FALSE, 
                        col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))
MAE_L_100_50_5<-read.csv("All_funvals_MAE_L_n_100_p_50_d_5_reps_10.csv", header=FALSE, 
                         col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))
MAE_L_100_100_5<-read.csv("All_funvals_MAE_L_n_100_p_100_d_5_reps_10.csv", header=FALSE, 
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


#############################################################################################################
## rank 10
MAE_L_50_10_10<-read.csv("All_funvals_MAE_L_n_50_p_10_d_10_reps_10.csv", header=FALSE, 
                        col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))
MAE_L_70_20_10<-read.csv("All_funvals_MAE_L_n_70_p_20_d_10_reps_10.csv", header=FALSE, 
                         col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))
MAE_L_100_50_10<-read.csv("All_funvals_MAE_L_n_100_p_50_d_10_reps_10.csv", header=FALSE, 
                         col.names= c("BOOOM","BOOOM_Parallel", "AccAlt_projection","GoDec_plus","LRSD_TNNSR"))
MAE_L_100_100_10<-read.csv("All_funvals_MAE_L_n_100_p_100_d_10_reps_10.csv", header=FALSE, 
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


#############################################################################################################################
final_data <- rbind(MAE_L_50_10_5_subset_long,
                    MAE_L_70_20_5_subset_long,MAE_L_100_50_5_subset_long,
                    MAE_L_100_100_5_subset_long,
                    MAE_L_50_10_10_subset_long,
                    MAE_L_70_20_10_subset_long,MAE_L_100_50_10_subset_long,
                    MAE_L_100_100_10_subset_long)
final_data$rank <- factor(final_data$rank, levels = c("rank 5", "rank 10"))

#### plots 2x4 log scale

p1 <- ggplot(final_data, aes(x = Methods, y = MAE, fill = Methods)) +
  geom_boxplot() + scale_y_log10()+
  facet_nested_wrap(vars(rank, dimension), 
                    scales = "free_y", nrow = 2,
                    strip= strip_nested(background_x = elem_list_rect(fill = "grey90"),
                                        background_y = elem_list_rect(fill = "grey80"),
                                        text_x = elem_list_text(face = "bold"), 
                                        text_y = elem_list_text(face = "bold")),
                    labeller = labeller(
                      dimension = c(
                        A="n=50, p=10",
                        B="n=70, p=20",
                        C="n=100, p=50",
                        D="n=100, p=100"
                      )
                    )) +
  scale_x_discrete(labels = c(
    "BOOOM_Parallel" = "BOOOM",
    "AccAlt_projection" = "AccAltProj",
    "GoDec_plus" = "GoDec+",
    "LRSD_TNNSR" = "LRSD-TNNSR"
  )) +
  scale_fill_discrete(
    breaks = c("BOOOM_Parallel","AccAlt_projection","GoDec_plus","LRSD_TNNSR"),
    labels = c("BOOOM","AccAltProj","GoDec+","LRSD-TNNSR")
  )+
  theme(axis.ticks.x = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_text(face = "bold"),
        legend.text = element_text(face = "bold"),
        legend.title = element_blank(),
        axis.title.y = element_markdown(),
        legend.position = "top")+
  labs(x = "", y = "MAE")

p1

ggsave("MAE_L.png", plot = p1, width = 6, height = 4, units = "in", dpi = 300)

