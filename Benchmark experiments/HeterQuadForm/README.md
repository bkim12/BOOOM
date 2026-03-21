## Required Dependency: CVX Toolbox

The CVX Toolbox is required to reproduce the simulation study.

Please download the CVX toolbox for MATLAB directly from the official website:

👉 https://cvxr.com/

After downloading and extracting, the `cvx` directory should have the following structure:

```text
cvx     
├── builtins
├── commands
├── doc
├── example
  ⋮       
├── Contents.m
├── cvx_error.m
├── cvx_setup.m
├── cvx_startup.m
├── cvx_version.m

```
Place the extracted `cvx` folder under the `supplement` folder. 

```text
HeterQuadForm
├── BOOOM
├── Simulation result
├── supplement
        ├── cvx
        ├── create_block_diagonal_PSD.m
	  ⋮	
├── simulation.m
└── summary.m

```

Install CVX by following the installation guide: https://cvxr.com/cvx/doc/install.html

## Semidefinite programming (SDP) relaxation code

Please download the semidefinite programming code `solve_sdp_CVX.m` from the original author's GitHub repository:

👉 https://github.com/kgilman/Sums-of-Heterogeneous-Quadratics

Store the `solve_sdp_CVX.m` file under the `supplement` folder. 

```text
HeterQuadForm
├── supplement
        ├── cvx
        ├── solve_sdp_CVX.m
        ├── create_block_diagonal_PSD.m
	  ⋮	
```

## Simulation Study: Heterogeneous quadratic form analysis

This simulation study evaluates the performance of BOOOM and semidefinite programming (SDP) relaxation on a class of heterogeneous quadratic form optimization problems over the Stiefel manifold.

$$\max_{Q \in \mathrm{St}(p,d)} \ \sum_{i=1}^{d} q_i^\top M_i q_i$$

where $M_1,\ldots,M_d \succeq 0\$ for $\(p>d\)$, $Q=[q_1 \ \cdots \ q_d]\in ℝ^{p\times d}$.

Simulations are performed under two dimension setting with $Q$:  $p\times d$ ∈ { $20\times 10$, $50\times 40$}. For each case, each matrix $M_i$ is $p\times p$.

The maximum value of the objective function (Heterogeneous quadratic form) is summarized and its corresponding plots reported in the manuscript.


## Code Reproducibility

To reproduce all numerical results reported in the main manuscript, please follow the steps below.

### Step 1: Run heterogeneous quadratic form simulations

Run the script `simulation.m` using following positive semidefinite matrix pattern:

- `input_types = 1` : random pattern  
- `input_types = 2` : toeplitz pattern  
- `input_types = 3` : block diagonal pattern  

For each pattern, set $p\times d$ = $20\times 10$ or $p\times d$ = $50\times 40$ in the code.


All simulation outputs are saved automatically to:

-  `HeterQuadForm/Simulation result/`. 

Example output files include:
- `All_funvals_random_p_20_d_10_reps_10.csv`
- `All_comp_times_random_p_20_d_10_reps_10.csv`


### Step 2: Aggregate Results

Next, execute the script `summary.m` to compile and summarize all simulation results.

All simulation outputs are saved to the same directory:

-  `HeterQuadForm/Simulation result/`. 

Example output files include:
- `summary_random_p_20_d_10.csv`
- `summary_toeplitz_p_20_d_10.csv`

These summary files contain the complete set of tables and aggregated results used in the manuscript.

### Step 3: Generate boxplots

Execute the script `plot.R` to generate the boxplots used in the manuscript.

Outputs are saved to: `Benchmark experiments/HeterQuadForm/`

