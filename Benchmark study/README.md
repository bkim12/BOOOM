## Manopt Toolbox Requirement

Manopt Toolbox is required to reproduce benchmark study analysis.

Please download the Manopt MATLAB toolbox directly from the official website:

👉 https://www.manopt.org/

After downloading and extracting the toolbox, the `manopt` directory should have the following structure:

```text
manopt
├── manopt/
     ├── autodiff
     ├── core
     ├── lifts
     ├── manifolds
     ├── solvers
     └── tools
├── examples
├── checkinstall.m
├── importmanopt.m
├── manopt_version.m

```
The extracted `manopt` folder should be stored under Benchmark study folder. 

```text
Benchmark study
├── manopt
├── Simulation result
├── supplement
├── benchmark_study.m
└── Summary.m

```


## Code Reproducibility

To reproduce all numerical results reported in the main manuscript, please follow the steps below.

### Step 1: Run Benchmark Simulations

Run the script `benchmark_study.m` for the following test functions:

- `input_vals = 1` : Ackley  
- `input_vals = 2` : Griewank  
- `input_vals = 3` : Rosenbrock  
- `input_vals = 4` : Rastrigin  

For each test function, set the problem dimension to `M = 10, 20, 50, 100`.

All simulation outputs are saved automatically to:

- `BOOOM/Benchmark/Simulation result/`. 

Example output files include:
- `All_funvals_ackley_M_10_reps_10.csv`
- `All_comp_times_ackley_M_10_reps_10.csv`


### Step 2: Aggregate Results

Finally, execute the script `Summary.m` to compile and summarize all benchmark results.

All summary output are saved in the same directory:
- `BOOOM/Benchmark/Simulation result/`
  
Example output files include:
- `Summary_ackley_M_10.csv`
- `Summary_griewank_M_10.csv`

These summary files contain the complete set of tables and aggregated results used in the manuscript.
