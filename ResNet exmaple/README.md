## Metabolite Profiling for Colorectal Cancer Association


This study analyzes a colorectal cancer (CRC) metabolite dataset consisting of 277 CRC patients and 110 metabolites.

1. Run `metabolite_analysis.m` to evaluate **model performance** across a grid of penalty combinations.
For each $(\lambda_1,\lambda_2)$ pair, the script computes: **misclassification rate** and **proportion of non zero columns** (sparsity).
In this study, $\lambda_1$ and  $\lambda_2$ take values **from $10^0$ to $10^8$**. To **keep the downstream scripts** (Pareto plot and optimal-solution analyses) aligned with the saved outputs, 
run the code by **fixing $\lambda_1$** and sweeping $\lambda_2$ from $10^0$ to $10^8$ in each run.
