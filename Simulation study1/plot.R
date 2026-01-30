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




# set working directory
setwd("Simulation result")


# read fun value csv file
funvals_random_M_p_20_d_10 <- read.csv("All_funvals_random_p_20_d_10_reps_10.csv", 
                                       col.names=c("BOOOM","BOOOM_Parallel","SDP"),header=FALSE)
funvals_toeplitz_M_p_20_d_10 <- read.csv("All_funvals_toeplitz_p_20_d_10_reps_10.csv", 
                                         col.names=c("BOOOM","BOOOM_Parallel","SDP"),header=FALSE)
funvals_block_diagonal_M_p_20_d_10 <- read.csv("All_funvals_block diagonal_p_20_d_10_reps_10.csv",
                                               col.names=c("BOOOM","BOOOM_Parallel","SDP"),header=FALSE)

funvals_random_M_p_50_d_40 <- read.csv("All_funvals_random_p_50_d_40_reps_10.csv", 
                                       col.names=c("BOOOM","BOOOM_Parallel","SDP"),header=FALSE)
funvals_toeplitz_M_p_50_d_40 <- read.csv("All_funvals_toeplitz_p_50_d_40_reps_10.csv", 
                                         col.names=c("BOOOM","BOOOM_Parallel","SDP"),header=FALSE)
funvals_block_diagonal_M_p_50_d_40 <- read.csv("All_funvals_block diagonal_p_50_d_40_reps_10.csv",
                                               col.names=c("BOOOM","BOOOM_Parallel","SDP"),header=FALSE)

############################################################################################# 
funvals_random_M_p_20_d_10$type <-"Random"
funvals_toeplitz_M_p_20_d_10$type <-"Toeplitz"
funvals_block_diagonal_M_p_20_d_10$type <-"Block diagonal"

funvals_random_M_p_50_d_40$type <-"Random"
funvals_toeplitz_M_p_50_d_40$type <-"Toeplitz"
funvals_block_diagonal_M_p_50_d_40$type <-"Block diagonal"


# size (matrix U size) A: 20x10, B: 50x40
p_20_d_10 <- rbind(funvals_random_M_p_20_d_10,funvals_toeplitz_M_p_20_d_10,funvals_block_diagonal_M_p_20_d_10)
p_20_d_10$size <-"A"

p_50_d_40 <- rbind(funvals_random_M_p_50_d_40,funvals_toeplitz_M_p_50_d_40,funvals_block_diagonal_M_p_50_d_40)
p_50_d_40$size <-"B"

# reshape to long format
df_long_p_20_d_10 <- pivot_longer(p_20_d_10, cols = c("BOOOM", "BOOOM_Parallel","SDP"), 
                                  names_to = "methods", 
                                  values_to = "value")

df_long_p_50_d_40 <- pivot_longer(p_50_d_40, cols = c("BOOOM", "BOOOM_Parallel","SDP"), 
                                  names_to = "methods", 
                                  values_to = "value")



#### 
data <- rbind(df_long_p_20_d_10,df_long_p_50_d_40)
data$type <- factor(data$type, levels = c("Random", "Toeplitz", "Block diagonal"))

############  plot with BOOOM Parallel and SDP only  
p1 <- data %>% filter(methods != "BOOOM") %>%
  ggplot(aes(x = methods, y = value, fill = methods)) +
  geom_boxplot(outlier.size = 1) +
  facet_nested_wrap(vars(size, type),
                    scales = "free_y",
                    labeller = labeller(size=c("A"="p=20,d=10","B"="p=50,d=40")),
                    strip= strip_nested(text_x = elem_list_text(face = "bold"),
                                        text_y = elem_list_text(face = "bold")))+
  scale_x_discrete(labels = c("BOOOM_Parallel" = "BOOOM", "SDP" = "SDP"))+
  scale_fill_manual(values = c("BOOOM_Parallel" = "tomato", "SDP" = "#619CFF"),
                    labels=c("BOOOM_Parallel" = "BOOOM", "SDP" = "SDP"))+
  theme(axis.ticks.x = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_text(face = "bold"),
        legend.text = element_text(face = "bold"),
        axis.title.y =element_text(face = "bold"),
        legend.position = "top")+
  labs(x = "", y = "Max value", fill = "")

p1
ggsave("HQ_max_value_plots.png", plot = p1, width = 7, height = 4.5, units = "in", dpi = 300)

