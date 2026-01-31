rm(list=ls())


# load library
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}
library(ggplot2)

# set working directory
setwd("Results")

# Plot importance score for lambda1: 10^6 lambda2: 10^3
###################################################################################
optimal_vars <- read.csv("var_ranks_QN.csv", header=FALSE)
non_zero_indicator <- read.csv("non_zeros_indicator_QN.csv", header=FALSE)
var_l2 <- read.csv("var_l2_vals_QN.csv", header=FALSE)
##
fun_clean_var <- function(x) sub("^[^_]*_", "", x)


## var 1  (lambda1: 10^6, lambda2: 10^3)
non_zero_indicator_var1 <- sum(non_zero_indicator[,1])
non_zero_vars_1 <- fun_clean_var(optimal_vars[1:20,1])
non_zero_l2_1 <- var_l2[1:20,1]


##
df_1 <- data.frame(var_names= non_zero_vars_1, l2_val=non_zero_l2_1)
# lollipop plot
p1 <- ggplot(df_1, aes(x = reorder(var_names, -l2_val), y = l2_val)) +
  # add the stick
  geom_segment(aes(x = reorder(var_names, -l2_val),
                   xend = reorder(var_names, -l2_val),
                   y = 0,
                   yend = l2_val),
               color = "grey40", linewidth = 1) +
  # add the circle
  geom_point(color = "black", fill = "blue", shape = 21, size = 3) +
  coord_cartesian(ylim = c(0.80, 0.98)) +
  theme_bw()+
  labs(y = "Measure of Importance Score", x = "") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1,
                                   color="black",face = "bold"),
        axis.text.y = element_text(face = "bold",size=8.5),
        axis.title.y =element_text(face = "bold",size=13),
        plot.title = element_text(color="black",size=17),
        axis.ticks.x = element_blank())
  

p1
ggsave("importance_score.png", plot = p1, width = 8, height = 6, units = "in", dpi = 300)
##########################################################
###################################################################################