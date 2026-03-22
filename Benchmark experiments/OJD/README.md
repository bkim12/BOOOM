## Manopt Toolbox Requirement

Manopt Toolbox is required to reproduce Orthogonal(Approximate) joint diagonalization.

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
The extracted `manopt` folder should be stored under OJD folder. 

```text
OJD
├── BOOOM
├── manopt
├── Outputs

```



## Benchmark experiments: Orthogonal(Approximate) joint diagonalization(OJD/AJD)

This simulation study evaluates the performance of BOOOM, JacobiAJD, Riemannian gradient descent and Riemannian trust-region to solve OJD problem.



The goal seeks an orthogonal matrix that makes a set of symmetric matrices simultaneously as diagonal as possible. Given symmmetric matrices $C_1,..., C_m \in ℝ^{p\times p}$, 
the problem is formulated as 

$$\min_{W \in \mathrm{St}(p,p)} \ \sum_{k=1}^{m} \Vert \text{offdiag}(W^TC_kW)\Vert_F^{2}$$

Here, $\text{offdiag}(\cdot)$ denotes the off-diagonal part of a matrix and $\Vert\cdot\Vert_F^{2}$ is the Frobenius norm.


Simulations are conducted under four dimension settings, specified by the the matrix dimension $p$ and the number of matrices $m$ $(p,m)$ ∈ { $(20, 5)$, $(20, 100)$, $(50, 5)$, $(50, 10)$ }.


## Code Reproducibility

To reproduce all numerical results reported in the main manuscript, please follow the steps below.

### Step 1: Independent component analysis study

Run the script `Comparison_study_OJD.m` 
Set the following matrix dimension: $X_{p\times n}$ as follows.

- `m` : the number of matrices
- `p` : dimension of orthogonal matrix

All simulation outputs are saved automatically to:

-  `OJD/Outputs/`

Example output files include:
- `Output_AJD_p_10_m_5_objVal.csv`
- `Output_AJD_p_10_m_5_summary.csv`
- `Output_AJD_p_10_m_5_time.csv`



### Step 2: Aggregate Results and Generate boxplots

Execute the script `Output_plot_OJD.R` to save summary table and generate the boxplots.

Outputs are saved to: `Benchmark experiments/OJD/`







