## Manopt Toolbox Requirement

Manopt Toolbox is required to reproduce a reduced Kohn-Sham Rayleigh-Ritz optimization

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
The extracted `manopt` folder should be stored under KohnSham folder. 

```text
KohnSham
├── BOOOM
├── manopt
├── Outputs

```


## Benchmark experiments: reduced Kohn–Sham Rayleigh–Ritz optimization

This experiment study evaluates the performance of BOOOM and Riemannian gradient descent on a reduced Kohn–Sham Rayleigh–Ritz optimization problem .

Given a Kohn-Sham Hamiltonian $H^*$ and an otrhonormal basis $B \in ℝ^{N_g\times p}$ for a reduced subspace, the projected Hamiltonian is defined by 

$$ H_{red} = B^TH^*B$$

The goal is to find an orthonormal matrix $Q \in St(p,d)$ that minimize 

$$ \min_{Q \in \mathrm{St}(p,d)} \text{tr}(Q^TH_{red}Q)   $$

Simulations are conducted under four reduced dimension settings $(p,d=2)$ ∈ { $(20, 2)$, $(50, 2)$, $(80, 2)$, $(100, 2)$ }.



## Code Reproducibility

To reproduce all numerical results reported in the main manuscript, please follow the steps below.

### Step 1: Independent component analysis study

Run the script `Comparison_study_reducedKS.m` 

Set the matrix dimension $(n,p)$ according to the following configurations.

- `nred` : the number of rows of B
- `p` : reduced subspace size, fixed as 2 (the number of columns)


All simulation outputs are saved automatically to:

-  `KohnSham/Outputs/`


### Step 2: Aggregate Results and Generate boxplots

Execute the script `Output_plot_KS.R` to save summary table and generate the boxplots.

Outputs are saved to: `Benchmark experiments/KohnSham/`

