## Simulation Study: Heterogeneous quadratic form analysis

This simulation study evaluates the performance of BOOOM and semidefinite programming (SDP) relaxation on a class of heterogeneous quadratic form optimization problems over the Stiefel manifold.

Simulations are conducted for dimensions of $Q$ $(p\times d)$ = $(20\times 10)$ or $(50\times 40)$ and dimension of $M$ $(p\times p)$ = $(20\times 20)$ or $(50\times 50)$

Maximum value over the objective function (Heterogeneous quadratic form) is summarized and its corresponding plots reported in the manuscript.


$$\max_{Q \in \mathrm{St}(p,d)} \ \sum_{i=1}^{d} q_i^\top M_i q_i$$

where $M_1,\ldots,M_d \succeq 0\$ for $\(p>d\)$, $Q=[q_1 \ \cdots \ q_d]\in ℝ^{p\times d}$.


### Step 1: 

Run the script `simulation.m` for the following positive semidefinite matrix pattern:

- `input_types = 1` : random pattern  
- `input_types = 2` : toeplitz pattern  
- `input_types = 3` : block diagonal pattern  

For each pattern, set the problem dimension to $(p\times d)$ = $(20\times 10)$ or $(50\times 40)$ in the code.


All simulation outputs are saved automatically to:

-  `BOOOM/Simulation study1/Simulation result/`. 

Example output files include:
- `All_funvals_random_p_20_d_10_reps_10.csv`
- `All_comp_times_random_p_20_d_10_reps_10.csv`


### Step 2: Results Aggregation

Finally, execute the script `summary.m` to compile and summarize all benchmark results.

All simulation outputs are saved in the same directory to simulation result:

-  `BOOOM/Simulation study1/Simulation result/`. 


Example output files include:
- `summary_random_p_20_d_10.csv`
- `summary_toeplitz_p_20_d_10.csv`

These summary files contain the complete set of tables and aggregated results used in the manuscript.
