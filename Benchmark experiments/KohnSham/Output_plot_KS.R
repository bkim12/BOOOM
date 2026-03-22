rm(list = ls())
setwd(file.path(getwd()))

library(tidyverse)

# ------------------------------------------------------------
# Helper function
# ------------------------------------------------------------

read_case <- function(file,label,metric){
  
  df <- read.csv(file, check.names = FALSE)
  
  df_long <- df %>%
    pivot_longer(cols = everything(),
                 names_to = "method",
                 values_to = "value") %>%
    mutate(case = label,
           metric = metric)
  
  return(df_long)
}

# ------------------------------------------------------------
# Read GAP data
# ------------------------------------------------------------

g1 <- read_case("Outputs/Output_KS_RR_nred_20_p_2_gap.csv","p = 20","Objective gap")
g2 <- read_case("Outputs/Output_KS_RR_nred_50_p_2_gap.csv","p = 50","Objective gap")
g3 <- read_case("Outputs/Output_KS_RR_nred_80_p_2_gap.csv","p = 80","Objective gap")
g4 <- read_case("Outputs/Output_KS_RR_nred_100_p_2_gap.csv","p = 100","Objective gap")

# ------------------------------------------------------------
# Read RESIDUAL data
# ------------------------------------------------------------

r1 <- read_case("Outputs/Output_KS_RR_nred_20_p_2_residual.csv","p = 20","KKT residual")
r2 <- read_case("Outputs/Output_KS_RR_nred_50_p_2_residual.csv","p = 50","KKT residual")
r3 <- read_case("Outputs/Output_KS_RR_nred_80_p_2_residual.csv","p = 80","KKT residual")
r4 <- read_case("Outputs/Output_KS_RR_nred_100_p_2_residual.csv","p = 100","KKT residual")

df <- bind_rows(g1,g2,g3,g4,r1,r2,r3,r4)

# ------------------------------------------------------------
# Clean method names
# ------------------------------------------------------------

df <- df %>%
  mutate(method = case_when(
    str_detect(method,"BOOOM") ~ "BOOOM",
    str_detect(method,"RCG") ~ "RCG",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(method))

df$method <- factor(df$method,
                    levels = c("BOOOM","RCG"))

# ------------------------------------------------------------
# Order facets
# ------------------------------------------------------------

df$case <- factor(df$case,
                  levels = c("p = 20",
                             "p = 50",
                             "p = 80",
                             "p = 100"))

df$metric <- factor(df$metric,
                    levels = c("Objective gap","KKT residual"))

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

method_colors <- c(
  "BOOOM" = "#E64B35",
  "RCG"   = "#4DBBD5"
)

# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------

p <- ggplot(df,
            aes(x = method, y = value, fill = method)) +
  
  geom_boxplot(width = .65,
               outlier.size = 1.5,
               colour = "black") +
  
  scale_y_log10() +
  
  facet_grid(metric ~ case,
             scales = "free_y",
             switch = "y") +
  
  scale_fill_manual(values = method_colors) +
  
  labs(x = NULL,
       y = NULL) +
  
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
    
    axis.text.x = element_text(size = 13, angle = 20, hjust = 1),
    
    panel.grid.major = element_line(colour = "grey90"),
    panel.grid.minor = element_blank(),
    
    panel.spacing.y = unit(2.0,"lines"),
    panel.spacing.x = unit(1.2,"lines")
  )
# ------------------------------------------------------------
# Save
# ------------------------------------------------------------

ggsave(
  "Boxplots_KS_results.png",
  p,
  width = 16,
  height = 9,
  dpi = 400
)

# ------------------------------------------------------------
# Summary table: median and IQR (Objective gap first, then KKT residual)
# ------------------------------------------------------------

library(dplyr)

summary_tbl <- df %>%
  group_by(metric, case, method) %>%
  summarise(
    median_value = median(value, na.rm = TRUE),
    IQR_value = IQR(value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    median_value = round(median_value, 4),
    IQR_value = round(IQR_value, 4)
  ) %>%
  arrange(metric, case, method)

# ------------------------------------------------------------
# Display table
# ------------------------------------------------------------

print(summary_tbl)

# ------------------------------------------------------------
# Save CSV
# ------------------------------------------------------------

write.csv(
  summary_tbl,
  "KohnSham_median_IQR_summary.csv",
  row.names = FALSE
)

cat("CSV saved: KohnSham_median_IQR_summary.csv\n")