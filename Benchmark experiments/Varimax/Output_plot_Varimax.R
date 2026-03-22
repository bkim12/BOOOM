rm(list = ls())
setwd(file.path(getwd()))

library(tidyverse)

# ------------------------------------------------------------
# Helper function
# ------------------------------------------------------------

read_case <- function(obj_file, label){
  
  df <- read.csv(obj_file, check.names = FALSE)
  
  df_long <- df %>%
    pivot_longer(cols = everything(),
                 names_to = "method",
                 values_to = "value") %>%
    mutate(case = label)
  
  return(df_long)
}

# ------------------------------------------------------------
# Read datasets
# ------------------------------------------------------------

d1 <- read_case("Outputs/Output_Varimax_p_30_q_5_objVal.csv",   "(n,p) = (30,5)")
d2 <- read_case("Outputs/Output_Varimax_p_60_q_5_objVal.csv",   "(n,p) = (60,5)")
d3 <- read_case("Outputs/Output_Varimax_p_50_q_10_objVal.csv",  "(n,p) = (50,10)")
d4 <- read_case("Outputs/Output_Varimax_p_100_q_10_objVal.csv", "(n,p) = (100,10)")
d5 <- read_case("Outputs/Output_Varimax_p_80_q_20_objVal.csv",  "(n,p) = (80,20)")
d6 <- read_case("Outputs/Output_Varimax_p_150_q_20_objVal.csv", "(n,p) = (150,20)")
d7 <- read_case("Outputs/Output_Varimax_p_120_q_30_objVal.csv", "(n,p) = (120,30)")
d8 <- read_case("Outputs/Output_Varimax_p_200_q_30_objVal.csv", "(n,p) = (200,30)")

df <- bind_rows(d1,d2,d3,d4,d5,d6,d7,d8)

# ------------------------------------------------------------
# Clean method names robustly
# ------------------------------------------------------------

df <- df %>%
  filter(!is.na(method)) %>%
  mutate(
    method = case_when(
      str_detect(method, "BOOOM") ~ "BOOOM",
      str_detect(method, "rotate") ~ "rotatefactors",
      TRUE ~ method
    )
  )

# ------------------------------------------------------------
# Factor order
# ------------------------------------------------------------

df$method <- factor(df$method,
                    levels = c("BOOOM","rotatefactors"))

# ------------------------------------------------------------
# Scenario order
# ------------------------------------------------------------

df$case <- factor(df$case,
                  levels = c("(n,p) = (30,5)",
                             "(n,p) = (60,5)",
                             "(n,p) = (50,10)",
                             "(n,p) = (100,10)",
                             "(n,p) = (80,20)",
                             "(n,p) = (150,20)",
                             "(n,p) = (120,30)",
                             "(n,p) = (200,30)"))
# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

method_colors <- c(
  "BOOOM" = "#E64B35",
  "rotatefactors" = "#4DBBD5"
)

# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------

p <- ggplot(df,
            aes(x = method, y = value, fill = method)) +
  
  geom_boxplot(width = .65,
               outlier.size = 1.5,
               colour = "black") +
  
  facet_wrap(~case,
             ncol = 4,
             nrow = 2,
             scales = "free_y") +
  
  scale_fill_manual(values = method_colors) +
  
  labs(x = NULL,
       y = expression(-V(R))) +   
  
  theme_bw(base_size = 18) +
  
  theme(
    legend.position = "top",
    legend.title = element_blank(),
    
    legend.text = element_text(size = 20),
    legend.key.size = unit(1.3,"cm"),
    
    strip.background = element_rect(fill = "grey92",
                                    colour = "grey40"),
    
    strip.text = element_text(size = 16, face = "bold"),
    
    axis.text.x = element_text(size = 13, angle = 20, hjust = 1),
    
    panel.grid.major = element_line(colour = "grey90"),
    panel.grid.minor = element_blank(),
    
    panel.spacing.y = unit(2.2, "lines")
  )

# ------------------------------------------------------------
# Save
# ------------------------------------------------------------

ggsave(
  "Boxplots_Varimax.png",
  p,
  width = 16,
  height = 8,
  dpi = 400
)


# ------------------------------------------------------------
# Summary table: median and IQR
# ------------------------------------------------------------

library(dplyr)
library(tidyr)

summary_tbl <- df %>%
  group_by(case, method) %>%
  summarise(
    median_value = median(value, na.rm = TRUE),
    IQR_value = IQR(value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    median_value = round(median_value, 4),
    IQR_value = round(IQR_value, 4)
  ) %>%
  arrange(case, method)

# ------------------------------------------------------------
# Display table in console
# ------------------------------------------------------------

print(summary_tbl)

# ------------------------------------------------------------
# Save long-format CSV
# ------------------------------------------------------------

write.csv(
  summary_tbl,
  "Varimax_median_IQR_summary.csv",
  row.names = FALSE
)
