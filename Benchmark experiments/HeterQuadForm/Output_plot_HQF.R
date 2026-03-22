rm(list=ls())
file.path(getwd())
library(tidyverse)

# ------------------------------------------------------------
# Read data
# ------------------------------------------------------------

funvals_random_M_p_20_d_10 <- read.csv(
  "Outputs/All_funvals_random_p_20_d_10_reps_10.csv",
  col.names=c("BOOOM","BOOOM_Parallel","SDP"),header=FALSE)

funvals_toeplitz_M_p_20_d_10 <- read.csv(
  "Outputs/All_funvals_toeplitz_p_20_d_10_reps_10.csv",
  col.names=c("BOOOM","BOOOM_Parallel","SDP"),header=FALSE)

funvals_block_diagonal_M_p_20_d_10 <- read.csv(
  "Outputs/All_funvals_block diagonal_p_20_d_10_reps_10.csv",
  col.names=c("BOOOM","BOOOM_Parallel","SDP"),header=FALSE)


funvals_random_M_p_50_d_40 <- read.csv(
  "Outputs/All_funvals_random_p_50_d_40_reps_10.csv",
  col.names=c("BOOOM","BOOOM_Parallel","SDP"),header=FALSE)

funvals_toeplitz_M_p_50_d_40 <- read.csv(
  "Outputs/All_funvals_toeplitz_p_50_d_40_reps_10.csv",
  col.names=c("BOOOM","BOOOM_Parallel","SDP"),header=FALSE)

funvals_block_diagonal_M_p_50_d_40 <- read.csv(
  "Outputs/All_funvals_block diagonal_p_50_d_40_reps_10.csv",
  col.names=c("BOOOM","BOOOM_Parallel","SDP"),header=FALSE)

# ------------------------------------------------------------
# Add scenario labels
# ------------------------------------------------------------

funvals_random_M_p_20_d_10$type <- "Random"
funvals_toeplitz_M_p_20_d_10$type <- "Toeplitz"
funvals_block_diagonal_M_p_20_d_10$type <- "Block diagonal"

funvals_random_M_p_50_d_40$type <- "Random"
funvals_toeplitz_M_p_50_d_40$type <- "Toeplitz"
funvals_block_diagonal_M_p_50_d_40$type <- "Block diagonal"

# ------------------------------------------------------------
# Combine sizes
# ------------------------------------------------------------

p_20_d_10 <- rbind(
  funvals_random_M_p_20_d_10,
  funvals_toeplitz_M_p_20_d_10,
  funvals_block_diagonal_M_p_20_d_10)

p_20_d_10$size <- "p = 20, d = 10"

p_50_d_40 <- rbind(
  funvals_random_M_p_50_d_40,
  funvals_toeplitz_M_p_50_d_40,
  funvals_block_diagonal_M_p_50_d_40)

p_50_d_40$size <- "p = 50, d = 40"

# ------------------------------------------------------------
# Long format
# ------------------------------------------------------------

df_long_p_20_d_10 <- pivot_longer(
  p_20_d_10,
  cols = c("BOOOM","BOOOM_Parallel","SDP"),
  names_to = "methods",
  values_to = "value")

df_long_p_50_d_40 <- pivot_longer(
  p_50_d_40,
  cols = c("BOOOM","BOOOM_Parallel","SDP"),
  names_to = "methods",
  values_to = "value")

data <- rbind(df_long_p_20_d_10, df_long_p_50_d_40)

data$type <- factor(data$type,
                    levels = c("Random","Toeplitz","Block diagonal"))

# ------------------------------------------------------------
# Filter methods (keep BOOOM parallel and SDP)
# ------------------------------------------------------------

data <- data %>% filter(methods != "BOOOM")

data$methods <- recode(data$methods,
                       "BOOOM_Parallel" = "BOOOM")

data$methods <- factor(data$methods,
                       levels=c("BOOOM","SDP"))

# ------------------------------------------------------------
# Color palette
# ------------------------------------------------------------

method_colors <- c(
  "BOOOM" = "#E64B35",
  "SDP"   = "#4DBBD5"
)

# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------

p1 <- ggplot(data,
             aes(x = methods, y = value, fill = methods)) +
  
  geom_boxplot(width = .65,
               outlier.size = 1.5,
               colour = "black") +
  
  facet_wrap(~ size + type,
             scales = "free_y",
             ncol = 3) +
  
  scale_fill_manual(values = method_colors) +
  
  labs(
    x = NULL,
    y = "Maximum objective value"
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
    
    strip.placement = "outside",
    
    axis.text.x = element_text(size = 14, angle = 20, hjust = 1),
    
    panel.grid.major = element_line(colour = "grey90"),
    panel.grid.minor = element_blank(),
    
    panel.spacing.y = unit(2.2, "lines")
  )
# ------------------------------------------------------------
# Save figure
# ------------------------------------------------------------

ggsave(
  "Boxplots_HQF.png",
  p1,
  width = 12,
  height = 7.3,
  dpi = 400
)