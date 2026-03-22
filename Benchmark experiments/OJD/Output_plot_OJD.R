rm(list = ls())
setwd(file.path(getwd()))

library(tidyverse)

# ------------------------------------------------------------
# Helper function
# ------------------------------------------------------------

read_case <- function(obj_file, label) {
  
  df <- read.csv(obj_file, check.names = FALSE)
  
  df_long <- df %>%
    pivot_longer(
      cols = everything(),
      names_to = "method",
      values_to = "value"
    ) %>%
    mutate(case = label)
  
  return(df_long)
}

# ------------------------------------------------------------
# Read datasets
# ------------------------------------------------------------

d1 <- read_case("Outputs/Output_AJD_p_20_m_5_objVal.csv",  "(p,m) = (20,5)")
d2 <- read_case("Outputs/Output_AJD_p_20_m_10_objVal.csv", "(p,m) = (20,10)")
d3 <- read_case("Outputs/Output_AJD_p_50_m_5_objVal.csv",  "(p,m) = (50,5)")
d4 <- read_case("Outputs/Output_AJD_p_50_m_10_objVal.csv", "(p,m) = (50,10)")

df <- bind_rows(d1, d2, d3, d4)

# ------------------------------------------------------------
# Clean method names robustly
# ------------------------------------------------------------

df <- df %>%
  filter(!is.na(method)) %>%
  mutate(
    method = case_when(
      str_detect(method, "Jacobi") ~ "JacobiAJD",
      str_detect(method, "RiemGD") ~ "RiemGD",
      str_detect(method, "RTR")    ~ "RiemTR",
      str_detect(method, "BOOOM")  ~ "BOOOM",
      TRUE ~ method
    )
  )

# ------------------------------------------------------------
# Method order
# ------------------------------------------------------------

df$method <- factor(
  df$method,
  levels = c("BOOOM", "JacobiAJD", "RiemGD", "RiemTR")
)

# ------------------------------------------------------------
# Scenario order
# ------------------------------------------------------------

df$case <- factor(
  df$case,
  levels = c("(p,m) = (20,5)",
             "(p,m) = (20,10)",
             "(p,m) = (50,5)",
             "(p,m) = (50,10)")
)

# ------------------------------------------------------------
# Color palette
# ------------------------------------------------------------

method_colors <- c(
  "BOOOM"     = "#E64B35",
  "JacobiAJD" = "#4DBBD5",
  "RiemGD"    = "#00A087",
  "RiemTR"       = "#3C5488"
)

# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------

p <- ggplot(df,
            aes(x = method, y = value, fill = method)) +
  
  geom_boxplot(
    width = 0.65,
    outlier.size = 1.5,
    colour = "black"
  ) +
  
  facet_wrap(
    ~ case,
    ncol = 2,
    nrow = 2,
    scales = "free_y"
  ) +
  
  scale_fill_manual(values = method_colors) +
  
  labs(
    x = NULL,
    y = "Objective value"
  ) +
  
  theme_bw(base_size = 18) +
  
  theme(
    legend.position = "top",
    legend.title = element_blank(),
    
    legend.text = element_text(size = 18),
    legend.key.size = unit(1.3, "cm"),
    
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
    panel.grid.minor = element_blank(),
    
    panel.spacing.x = unit(1.0, "lines"),
    panel.spacing.y = unit(1.8, "lines")
  )

# ------------------------------------------------------------
# Save
# ------------------------------------------------------------

ggsave(
  "Boxplots_AJD.png",
  p,
  width = 12,
  height = 8.5,
  dpi = 400
)


# ------------------------------------------------------------
# Summary table: median and IQR
# ------------------------------------------------------------

library(dplyr)

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
# Display in console
# ------------------------------------------------------------

print(summary_tbl)

# ------------------------------------------------------------
# Save CSV
# ------------------------------------------------------------

write.csv(
  summary_tbl,
  "OJD_median_IQR_summary.csv",
  row.names = FALSE
)

cat("CSV saved: OJD_median_IQR_summary.csv\n")
