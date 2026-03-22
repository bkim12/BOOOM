rm(list=ls())
setwd(file.path(getwd()))

library(tidyverse)
library(patchwork)

# ------------------------------------------------------------
# Helper function
# ------------------------------------------------------------

read_case <- function(obj_file, amari_file, label){
  
  obj  <- read.csv(obj_file, check.names = FALSE)
  amari <- read.csv(amari_file, check.names = FALSE)
  
  obj_long <- obj %>%
    pivot_longer(
      cols = everything(),
      names_to = "method",
      values_to = "value"
    ) %>%
    mutate(metric = "Objective",
           case = label)
  
  amari_long <- amari %>%
    pivot_longer(
      cols = everything(),
      names_to = "method",
      values_to = "value"
    ) %>%
    mutate(metric = "Amari",
           case = label)
  
  bind_rows(obj_long, amari_long)
}

# ------------------------------------------------------------
# Read datasets
# ------------------------------------------------------------

d1 <- read_case(
  "Outputs/Output_ICA_p_20_n_50_objVal.csv",
  "Outputs/Output_ICA_p_20_n_50_AMARI.csv",
  "n = 50, p = 20"
)

d2 <- read_case(
  "Outputs/Output_ICA_p_20_n_200_objVal.csv",
  "Outputs/Output_ICA_p_20_n_200_AMARI.csv",
  "n = 200, p = 20"
)

d3 <- read_case(
  "Outputs/Output_ICA_p_50_n_125_objVal.csv",
  "Outputs/Output_ICA_p_50_n_125_AMARI.csv",
  "n = 125, p = 50"
)

d4 <- read_case(
  "Outputs/Output_ICA_p_50_n_500_objVal.csv",
  "Outputs/Output_ICA_p_50_n_500_AMARI.csv",
  "n = 500, p = 50"
)

df <- bind_rows(d1,d2,d3,d4)

df$case <- factor(
  df$case,
  levels = c(
    "n = 50, p = 20",
    "n = 200, p = 20",
    "n = 125, p = 50",
    "n = 500, p = 50"
  )
)

# ------------------------------------------------------------
# Method order
# ------------------------------------------------------------

df$method <- factor(
  df$method,
  levels = c("BOOOM","FastICA","RunICA","Picard")
)

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

method_colors <- c(
  "BOOOM"  = "#E64B35",
  "FastICA" = "#4DBBD5",
  "RunICA"  = "#00A087",
  "Picard"  = "#3C5488"
)

# ------------------------------------------------------------
# Plot function
# ------------------------------------------------------------

plot_metric <- function(metric_name){
  
  ggplot(
    df %>% filter(metric == metric_name),
    aes(x = method, y = value, fill = method)
  ) +
    
    geom_boxplot(
      width = .65,
      outlier.size = 1.6,
      colour = "black"
    ) +
    
    facet_wrap(
      ~case,
      nrow = 1,
      scales = "free_y"
    ) +
    
    scale_fill_manual(
      values = method_colors,
      labels = c("BOOOM","FastICA","Infomax","Picard")  # rename RunICA
    ) +
    
    scale_x_discrete(
      labels = c("BOOOM","FastICA","Infomax","Picard")  # rename RunICA
    ) +
    
    labs(
      x = NULL,
      y = metric_name
    ) +
    
    theme_bw(base_size = 18) +
    
    theme(
      legend.position = "top",
      legend.title = element_blank(),
      
      legend.text = element_text(size = 20),   # larger legend
      legend.key.size = unit(1.4,"cm"),
      
      strip.background = element_rect(
        fill = "grey92",
        colour = "grey40"
      ),
      
      strip.text = element_text(
        size = 16,
        face = "bold"
      ),
      
      axis.text.x = element_text(
        size = 13,
        angle = 20,
        hjust = 1
      ),
      
      panel.grid.major = element_line(colour = "grey90"),
      panel.grid.minor = element_blank()
    )
}

# ------------------------------------------------------------
# Generate panels
# ------------------------------------------------------------

p_obj  <- plot_metric("Objective")
p_amari <- plot_metric("Amari")

final_plot <- (p_obj / p_amari) +
  plot_layout(guides = "collect") &
  theme(legend.position = "top")

# ------------------------------------------------------------
# Save figure
# ------------------------------------------------------------

ggsave(
  "Boxplots_ICA.png",
  final_plot,
  width = 15,
  height = 8.5,   # taller figure
  dpi = 400
)



# ------------------------------------------------------------
# Median + IQR summary and LaTeX table generation
# ------------------------------------------------------------

library(dplyr)
library(tidyr)

summary_tbl <- df %>%
  group_by(metric, case, method) %>%
  summarise(
    median = median(value),
    IQR = IQR(value),
    .groups = "drop"
  )

summary_tbl <- summary_tbl %>%
  mutate(
    median = round(median,3),
    IQR = round(IQR,4)
  )

write.csv(
  summary_tbl,
  "ICA_median_IQR_summary.csv",
  row.names = FALSE
)

print(summary_tbl)