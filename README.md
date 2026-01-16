# BOOOM: Black-box Optimization over Orthonormal Manifolds

**BOOOM** (*Black-box Optimization over Orthonormal Manifolds*) is a general-purpose global optimization method for **orthonormal matrix estimation** under **any form of objective functions (non-convex, multi-modal, non-differentiable)**.

BOOOM operates **directly on the Stiefel manifold space**, ensuring an **orthonormal matrix at every iteration**, while supporting **global, gradient-free optimization**. This approach leverages **recursive pattern search algorithm**.

---

### Notation note
The Stiefel manifold is the set of all matrices with orthonormal columns. We define it as $\mathrm{St}(p,d)=\lbrace Q\in ℝ^{p\times d}: Q^\top Q=I_d\,\rbrace$, i.e, the set of $p\times d$ (column) orthonormal matrices. We focuse on the case $(p \geq d)$ in the project.

---


## Repository Structure


```text
BOOOM/
├── Benchmark/                 # Benchmark experiments and comparisons
├── Real data analysis/        # Real-data application (.... analysis)
├── Simulation study1/         # Simulation study (Heterogeneous quadratic form analysis)
├── Simulation study2/         # Simulation study (Low rank and sparse matrix decomposition analysis)
├── figures/                   # Figures used in the paper/README (e.g., diagrams, flowcharts)
└── README.md                  # Main repository README
```



---

## Key Features

- **Guaranteed validity**  
  Every iterate produced by BOOOM is under the Stiefel manifold $\mathrm{St}(p,d)$.
  
- **Black-box optimization**  
  The objective function only needs to be *evaluated*. No gradients, Hessians, likelihood structure, or smoothness assumptions are required.

- **Penalty-agnostic**  
  Supports both convex and non-convex penalties fully customizable user-defined penalties.

- **Global exploration**  
  Built-in restart and step-size reset mechanisms allow the algorithm to systematically escape poor local minima and explore the objective landscape.

- **Parallelizable**  
  Coordinate-wise objective evaluations can be executed in parallel.  
  For a $p\times d$ orthonormal matrix, up to $p(p−1)$ coordinate directions can be evaluated simultaneously.
  
- **Scalable to high dimensions**  
  Designed to perform reliably in dimensional $(p \geq d)$.

---


##  Problem Setting

Let O denote an orthonormal  $p\times d$  matrix $p \geq d$.  
BOOOM solves optimization problems of the form:

<pre>
minimize   f(Q)
subject to Q ∈ St(p,d)
</pre>

where:

- **$f(\cdot)$** is an arbitrary real-valued function 
---


##   Method Overview


BOOOM repramatrize domain space $\mathrm{St}(p,d)$ to $𝜃 ∈ (0, \pi)$ search over rotation parameters, enabling the use of robust black-box optimization techniques.
BOOOM leverages a complete Givens rotation  to reparameterize the Stiefel manifold.
Starting from a fixed orthonormal base matrix $Q_0 ∈ St(p,d)$, any point on $\mathrm{St}(p,d)$ can be reaced by premultiplying a finite sequence of Givens rotations,
each rotating two coordinate axes by an angle  $𝜃 ∈ (0, \pi)$

BOOOM represents **candidate solutions** as

$$Q_{new}= R_{ij}(\theta)Q_0,   1 \leq i < j \leq p$$

<p align="center">
  <img src="figures/Fermis_principle_constraint.png" width="70%">
</p>


Where Givens rotation is defined as

$$
R_{i,j}(\theta)=
\begin{bmatrix}
1 & \cdots & 0 &    \cdots    &     0   &     \cdots   & 0\\
\vdots & \ddots & \vdots &        &    \vdots    &        & \vdots\\
0 & \cdots & \cos\theta & \cdots & -\sin\theta     & \cdots & 0\\
\vdots &        & \vdots & \ddots & \vdots &        & \vdots\\
0 & \cdots & \sin\theta & \cdots & \cos\theta      & \cdots & 0\\
\vdots &        & \vdots &        & \vdots & \ddots & \vdots\\
0 & \cdots & 0 &      \cdots  &    0    &     \cdots   & 1
\end{bmatrix}_{p\times p}
$$

This parameterization:

- Preserves orthonormality by construction
- Converts manifold constraints into bounded scalar parameters


---
### Optimization via Recursive Modified Pattern Search (RMPS)

Once parameterized, BOOOM performs optimization using Recursive Modified Pattern Search (RMPS), a derivative-free global optimization algorithm.
RMPS explores the rotation parameters by:

- Evaluating coordinate-wise perturbations of rotation angles
- Recursively refining promising directions
- Parallel local searches in parameter space


The objective function is evaluated only at the matrix under the valid Stiefel manifold generated via rotations.


<p align="center">
  <img src="figures/BOOOM_concept.png" width="85%">
</p>
