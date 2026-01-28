## Metabolite Profiling for Colorectal Cancer Association


This study analyzes a colorectal cancer (CRC) metabolite dataset consisting of 277 CRC patients and 110 metabolites.

1. Run `metabolite_analysis.m` to evaluate **model performance** across a grid of penalty combinations.
For each $(\lambda_1,\lambda_2)$ pair, the script computes: **misclassification rate** and **proportion of non zero columns** (sparsity).
In this study, $\lambda_1$ and  $\lambda_2$ take integer values **from 0 to 8**. To **keep the downstream scripts** (Pareto plot and optimal-solution analyses) aligned with the saved outputs, 
run the code by **fixing $\lambda_1$** and sweeping $\lambda_2$ from 0 to 8 in each run.

      **output**: Q_matrices_d_20_0.m, Result_n_277_p_110_d_20_0.csv.    
      The trailing `_0` in each filename denotes the $\lambda_1$ value used for that run (e.g., `_0` corresponds to $\lambda_1 = 0$).

3. Run `pareto_plot.R` to read the results from Step 1 and plots the **Pareto plot**, highlighting penalty combinations that give the best trade-off between misclassification rate and sparsity.  

    **output**: pareto_plot.png

3. Run `analysis_Q_matrix.m` to interpret which **metabolites contribute** to the solution at each Pareto optimal point.  

    **output**: var_ranks_QN.csv, var_l2_vals_QN.csv, non_zeros_indicator_QN.csv

4. Run `importance_score_plot.m` to **visualize importance scores**, showing the top 20 metabolites for one Pareto-optimal solution.  

    **output**: importance_vars_v3.png


For data preparation, run `data_setup.R`

## 🔐 Data Access

Dataset is shared at `Reproducible codes/Real Data Analysis/Data/Yachida_BMASTER/`. The raw dataset was originally shared with the following publication:

- *Muller et al. (2022)*, ‘The gut microbiome-metabolome dataset collection: a curated resource for integrative meta-analysis’, npj Biofilms and Microbiomes 8(1), 79.

---
