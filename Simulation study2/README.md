## Required Dependencies: 

- AccAltProj (Accelerated Alternating Projections)

👉 https://github.com/caesarcai/AccAltProj_for_RPCA

**PROPACK** toolbox is required to run AccAltProj successfully.
You can download the PROPACK from `http://sun.stanford.edu/~rmunk/PROPACK/`.
Alternatively, you can use the PROPACK files included in the author’s AccAltProj GitHub repository, which contains the required components.

- LRSD-TNNSR (Low-rank and sparse matrix decomposition via the truncated nuclear norm and a sparse regularizer)

👉 https://github.com/xuezc/LRSD-TNNSR

- GoDec+

👉 https://github.com/CollinGuo/GoDec_plus

For copyright reasons, the GoDec+ source files are not included in this repository. 
Please download `lowrank_corr.m` from the author’s GitHub repository and place it under `supplement/GoDec_plus/`

This repository includes code and implementations adapted from the following
open-source projects:

- **AccAltProj (Accelerated Alternating Projections)**  
  https://github.com/caesarcai/AccAltProj_for_RPCA  
  Licensed under the MIT License  
  Copyright (c) 2019 HanQin Cai, Jian-Feng Cai, Ke Wei

- **LRSD-TNNSR (Low-rank and sparse matrix decomposition via the truncated nuclear norm and a sparse regularizer)**  
  https://github.com/xuezc/LRSD-TNNSR  
  Licensed under the GNU General Public License v3 (GPLv3)  
  Copyright (c) 2018 Z. Xue, J. Dong, Y. Zhao, C. Liu, and R. Chellali  

Minor modifications were made for reproducibility and experimental consistency,
including updates to MATLAB path settings, default parameter values, and
script organization. All original copyright and license notices are preserved.

Modified portions of LRSD-TNNSR remain licensed under GPLv3 and are provided
for research and non-commercial use only, in accordance with the original
authors’ licensing terms.


After downloading the required packages, the directory should have the following structure:

```text
Simulation study2
├── BOOOM
├── Simulation result
├── supplement
  ├── AccAltProj
    ├── PROPACK
    ├── AccAltProj_synthetic.m
    ├── trim.m
  ├── GoDec_plus
    ├── lowrank_corr.m
  ├── LRSD-TNNSR
    ├── admm_pic.m
    ├── admmAXB.m
  ├── eval_metrics.m
  ├── generate_data.m
	  ⋮	
├── simulation.m
└── summary.m

```


## Low-rank and Sparse Matrix Decomposition


This simulation study evaluates the performance of BOOOM and three algorithms for low-rank and sparse matrix decomposition

We consider $X = L + S$ where $X_{n\times p}$ is the original data,  $L_{n\times p}$ is a low-rank approximation with rank $d$ and $S_{n\times p}$ is a sparse matrix.

Simulations are conducted under multiple settings for $X$, with dimension $(n\times p)$ ∈ { ($50\times 10$), ($70\times 20$), ($100\times 50$), ($100\times 100$)}.
For each dimension setting, we consider two choices of the rank of the low-rank component, namely $d=5$ and $d=10$.

The performance is evaluated using the mean absolute error (MAE) between the estimated low-rank component $\hat{L}$ and the true low rank matrix $L$.
The MAE values are summarized, and the corresponding plots are reported in the manuscript.



## Code Reproducibility

To reproduce all numerical results reported in the main manuscript, please follow the steps below.    
    **Note:** GoDec+ may not reproduce identical results due to its algorithmic nature.

### Step 1: Run low rank and sparse matrix decomposition simulations

Run `simulation.m`.
Set the following matrix dimension: $X_{n\times p}$ as follows.

- `n` : the number of rows 
- `p` : the number of columns
- `d` : target rank of the low-rank matrix $L$  


All simulation outputs are saved automatically to:

-  `BOOOM/Simulation study2/Simulation result/`

Example output files include:
- `All_funvals_MAE_L_n_50_p_10_d_5_reps_10.csv`
- `All_comp_times_n_50_p_10_d_5_reps_10.csv`


### Step 2: Aggregate Results

Next, execute the script `summary.m` to compile and summarize all simulation results.

All outputs are saved to the same directory:

-  `BOOOM/Simulation study2/Simulation result/`


Example output files include:
- `summary_MAE_L_n_50_p_10_d_5.csv`
- `summary_MAE_L_n_50_p_10_d_10.csv`

These summary files contain the complete set of tables and aggregated results used in the manuscript.

### Step 3: Generate boxplots

Execute the script `plot.R` to generate the boxplots used in the manuscript.

Outputs are saved to: `BOOOM/Simulation study2/Simulation result/`
