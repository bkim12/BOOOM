## Benchmark experiments: Independent component analysis(ICA)

This simulation study evaluates the performance of BOOOM, FastICA, Infomax and Picard to solve the ICA problem.
ICA seeks to recover statistically independent latent sources from observed linear mixtures. Given an observed data matrix

$$X = AS$$

where $X\in  ℝ^{p\times n}$ is an observed data that constructed from an unknown mixing matrix $A \in  ℝ^{p\times p}$ and latent independent source signals $S \in  ℝ^{p\times n}$.

The goal is to estimate an unmixing matrix $W$ to recover signals $\hat{S} = WX$ by maximizing the log-cosh contrast function as follows:


$$\max_{W \in \mathrm{St}(p,p)} \ \sum_{t=1}^{n} \sum_{i=1}^{p} \text{log cosh}(a_1 w_i^T x_t)$$

where $w_i$ refers to the $i$-th row of W, $x_t$ represents the $t$-th observations and $a_i>0$ is fixed at 1 in this experiments.

Simulations are conducted under four dimension settings where the observed data matroix $X \in (p\times n)$ ∈ { $(20\times 50)$, $(20\times 200)$, $(50\times 125)$, $(50\times 500)$ }.

The Amari distance is used to assess and compare the accuracy of source recovery across the different methods.


## Code Reproducibility

To reproduce all numerical results reported in the main manuscript, please follow the steps below.

### Step 1: Independent component analysis study

Run the script `Comparison_study_ICA.m` 
Set the following matrix dimension: $X_{p\times n}$ as follows.

- `n` : sample size
- `p` : the number of source signals


All simulation outputs are saved automatically to:

-  `ICA/Outputs/`

Example output files include:
- `Output_ICA_p_20_n_50_objVal.csv`
- `Output_ICA_p_20_n_50_AMARI.csv`




### Step 2: Aggregate Results and Generate boxplots

Execute the script `Output_plot_ICA.R` to save summary table and generate the boxplots.

Outputs are saved to: `Benchmark experiments/ICA/`






