## Benchmark experiments: Varimax Factor Rotation

This simulation study evaluates the performance of BOOOM and the classic Varimax rotation function in matlab (rotatefactors) to find an orthogonal rotation matrix that maximizes the Varimax criterion.

Given a loading matrix $A \in  ℝ^{n\times p}$, the goal is to find an orthogonal rotation matrix $R \in St(p,p)$ such that the rotated loading matrix $B=AR$ has a simple and interpretable structure.  

The Varimax criterion is defined by,

$$ V(R) = \sum_{j=1}^{p} \left[\frac{1}{n}\sum_{k=1}^{n} B_{kj}^{4}- \left(\frac{1}{n}\sum_{k=1}^{n} B_{kj}^{2}\right)^2 \right] $$

In our implementation, we reformulate the problem as minimizing the objective function $-V(R)$

Simulations are conducted under eight dimension settings where the dimension of loading matrix $A$ $(n,p)$ ∈ { $(30, 5)$, $(60, 5)$, $(50, 10)$, $(100, 10)$ , $(80, 20)$, $(150, 20)$ , $(120, 30)$, $(200, 30)$ }.



## Code Reproducibility

To reproduce all numerical results reported in the main manuscript, please follow the steps below.

### Step 1: Independent component analysis study

Run the script `Comparison_study_Varimax.m` 

Set the matrix dimension $(n,p)$ according to the following configurations.

** Note** : 
The paper uses $(n,p)$ to represent the matrix dimensions, where $n$ is the number of rows and $p$ is the number of columns. In the code, the same dimensions are written as
$(p,q)$, so the paper's $(n,p)$  corresponds directly to $(p,q)$ in the implementation.

All simulation outputs are saved automatically to:

-  `Varimax/Outputs/`

Example output files include:
- `Output_Varimax_p_30_q_5_objVal.csv`


### Step 2: Aggregate Results and Generate boxplots

Execute the script `Output_plot_Varimax.R` to save summary table and generate the boxplots.

Outputs are saved to: `Benchmark experiments/Varimax/`
