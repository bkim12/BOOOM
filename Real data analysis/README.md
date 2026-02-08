## Metabolite Profiling for Colorectal Cancer Association


This study analyzes a colorectal cancer (CRC) metabolite dataset consisting of 277 CRC patients and 110 metabolites.

1. Run `metabolite_analysis.m` to evaluate **model performance** across a grid of penalty combinations.
For each $(\lambda_1,\lambda_2)$ pair, the script computes: **misclassification rate** and **proportion of non zero columns** (sparsity).
In this study, $\lambda_1$ and  $\lambda_2$ take values **from $10^0$ to $10^8$**. To **keep the downstream scripts** (Pareto plot and optimal-solution analyses) aligned with the saved outputs, 
run the code by **fixing $\lambda_1$** and sweeping $\lambda_2$ from $10^0$ to $10^8$ in each run.

      **output**: `Q_matrices_d_20_0.m`, `Result_n_277_p_110_d_20_0.csv`.    
      The trailing `_0` in each filename denotes the exponent $\lambda_1$ value used for that run (e.g., `_0` corresponds to $\lambda_1 = 10^0$).

   `Q_matrices_d_20_0.m` is a 9×1 cell array containing optimal Q matrices for a fixed $\lambda_1 = 10^0$ and varying $\lambda_2 \in {10^0, 10^1, \dots, 10^8}$. The $i$-th cell corresponds to $\lambda_2 = 10^{i-1}$; for example, the first cell contains the optimal Q matrix for $(\lambda_1, \lambda_2) = (10^0, 10^0)$, and the second cell corresponds to $(10^0, 10^1)$.

      **Note**: The code generates the files Result_n_277_p_110_d_20_0.csv through Result_n_277_p_110_d_20_9.csv. The file `final_result.csv` was created by manually concatenating these CSV files in order. The final_result.csv file is used in **Step 2** to generate the Pareto plot.

2. Run `pareto_plot.R` to read the results from Step 1 and plots the **pareto plot**, highlighting penalty combinations that give the best trade-off between misclassification rate and sparsity.
    
    **output**: pareto_plot.png

3. Run `analysis_Q_matrix.m` to interpret which **metabolites contribute** to the solution at each Pareto optimal point.  

    **output**: var_ranks_QN.csv, var_l2_vals_QN.csv, non_zeros_indicator_QN.csv

4. Run `importance_score_plot.m` to **visualize importance scores**, showing the top 20 metabolites for one Pareto-optimal solution.  

    **output**: importance_score.png


## 🔐 Data Access

Dataset is shared at `/Real data analysis/Data/`. The raw dataset was originally shared with the following publication:

- *Muller et al. (2022)*, ‘The gut microbiome-metabolome dataset collection: a curated resource for integrative meta-analysis’, npj Biofilms and Microbiomes 8(1), 79.

---
