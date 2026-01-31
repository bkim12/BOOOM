rm(list=ls())

# load library
if (!requireNamespace("dplyr", quietly = TRUE)) {
  install.packages("dplyr")
}
library(dplyr)


if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}
library(ggplot2)

if (!requireNamespace("ggrepel", quietly = TRUE)) {
  install.packages("ggrepel")
}
library(ggrepel)

setwd("Results")
###################################################################################
###### plot with Quantile normalization and scaled simulation result
final_result <- read.csv("final_result.csv", header=FALSE, 
                         col.names = c("lambda1", "lambda2", "misclassification","non_zero_rate","zero_out_of_non_zero","time","fvals"))



pareto_front <- function(df, x = "misclassification", y = "non_zero_rate") {
  d <- df %>% arrange(.data[[x]], .data[[y]])
  # running minimum of y as x increases
  run_min <- cummin(d[[y]])
  # keep rows where the running minimum strictly decreases (new best y)
  keep <- c(TRUE, head(run_min, -1) > tail(run_min, -1))
  d[keep, , drop = FALSE]
}

front <- pareto_front(final_result)


front_subset <- subset(front, non_zero_rate <= 0.5) 

#### subset data points on 
front_subset$exponent_1 <- log10(front_subset$lambda1)  
front_subset$exponent_2 <- log10(front_subset$lambda2)  

front_subset$label <- with(front_subset,
                       sprintf('bold(lambda[1]*": "*10^%s*", "*lambda[2]*": "*10^%s)', exponent_1, exponent_2))


front_subset_2<-subset(front_subset, !(exponent_1==4&exponent_2==1))
front_subset_3<-subset(front_subset, exponent_1==4&exponent_2==1 )

###### pareto_curves plot 
p1<-ggplot(final_result, aes(misclassification, non_zero_rate)) +
  geom_point(size=2.5) +
  # highlight frontier points
  geom_point(data = front_subset, color = "darkred",size=2.5) +
  # connect them (monotone decreasing)
  geom_path(data = front_subset, color = "darkred") +
  geom_text_repel(data = front_subset_2,
                  aes(label = label),
                  parse = TRUE,
                  color = "slateblue4",
                  size = 5,
                  nudge_x = -0.01,
                  direction = "x",
                  hjust = 1)  + 
  geom_text_repel(data = front_subset_3,
                  aes(label = label),
                  parse = TRUE,
                  color = "slateblue4",
                  size = 5,
                  nudge_x = -0.02,
                  nudge_y = 0.01,
                  hjust = 0.5)  +
  # coord_cartesian(ylim=(c(0.2,0.48)),xlim=(c(0.28,0.40)))+
  scale_y_continuous(limits = c(0.2, 0.49),expand=c(0.0)) +
  scale_x_continuous(limits = c(0.275, 0.41),expand=c(0.0)) +
  labs(x='Misclassification Rate',y='Prop. of non-zero columns')+
  theme_bw()+
  theme(axis.title.x = element_text(face = "bold",size = rel(1.2)), 
        axis.title.y = element_text(face = "bold",size = rel(1.2)),
        axis.text.x = element_text(face = "bold",size = rel(1.1)),
        axis.text.y = element_text(face = "bold",size = rel(1.1))
        )
p1
ggsave("pareto_plot.png", plot = p1, width = 8, height = 6, units = "in", dpi = 300)
