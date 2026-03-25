## Required Dependency: CVX Toolbox & KSSOLV 

Manopt Toolbox are KSSOLV(KSSOLV2.0) are required to reproduce a reduced Kohn-Sham Rayleigh-Ritz optimization

Please download the Manopt MATLAB toolbox and KSSOLV2.0 directly from the official website:

👉 https://www.manopt.org/

👉 https://www.kssolv.org/

After downloading and extracting the files, the `manopt` and `kssolv2.0` directories should have the following structure:

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

```text
kssolv2.0
├── docs
├── examples
├── external
├── kssolvsrc
    ├── SCF_DCM
        ├── scf.m
├── ppdata

```


The extracted `manopt` and `kssolv2.0` file folders should be placed under supplement folder. 

```text
supplement
├── kssolv2.0
├── manopt

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

