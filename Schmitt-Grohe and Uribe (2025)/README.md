# Schmitt-Grohe and Uribe (2025)

## Paper

**"Heterogeneous Downward Nominal Wage Rigidity: Foundations of a Nonlinear Phillips Curve"**  
Stephanie Schmitt-Grohé and Martín Uribe (2025 working paper)

The paper builds a model with **heterogeneous downward nominal wage rigidity (HDNWR)** across a continuum of labour varieties. The degree of wage rigidity varies across workers and occupations rather than being uniform. This delivers a smooth, convex wage Phillips curve that is steep at high inflation and flat at low inflation — without requiring market power or forward-looking wage-setting. The model is amenable to standard perturbation methods (Dynare) despite featuring occasionally binding constraints at the micro level.

---

## Folder Structure

```
Schmitt-Grohe and Uribe (2025)/
│
├── hdnwr.mod                        # Dynare model file (first-order perturbation)
├── hdnwr_steadystate.m              # Steady-state solver for hdnwr.mod
│
├── hdnwr_nl.mod                     # Dynare model file (second-order perturbation)
├── hdnwr_nl_steadystate.m           # Steady-state solver for hdnwr_nl.mod
│
├── plot_phillips_curve.m            # Visualisation: static nonlinear Phillips curve
├── plot_asymmetric_irfs.m           # Visualisation: asymmetric IRFs (±monetary shock)
├── plot_stochastic_scatter.m        # Visualisation: stochastic simulation scatter plot
│
├── fig_phillips_curve.pdf           # Output: nonlinear Phillips curve figure
├── fig_asymmetric_irfs.pdf          # Output: asymmetric IRFs figure
├── fig_stochastic_scatter.pdf       # Output: stochastic scatter plot figure
│
├── hdnwr/                           # Dynare output folder (first-order run)
│   ├── Output/hdnwr_results.mat     # Saved results (IRFs, steady state, etc.)
│   └── graphs/                      # Auto-generated IRF plots (.eps)
│
├── hdnwr_nl/                        # Dynare output folder (second-order run)
│   ├── Output/hdnwr_nl_results.mat  # Saved results (IRFs, stochastic simulation)
│   └── graphs/                      # Auto-generated IRF plots (.eps)
│
├── readings/                        # Reference materials
│   ├── Schmitt-Grohe and Uribe (2025 wp).pdf
│   └── sgu_paper_summary.md
│
├── Schmitt-Grohe and Uribe (2025 wp).pdf  # Original working paper
├── sgu_paper_summary.md             # Detailed paper summary
├── schmittgrohe_uribe_ocr.md        # OCR of paper content
└── changes_summary.md               # Replication log
```

---

## File Descriptions

### Core Model Files

#### `hdnwr.mod`
The main Dynare model file implementing the HDNWR model with **endogenous labour supply** (Definition C1, Appendix C of the paper). Solved at **first order** (`order=1`).

- **10 endogenous variables:** `jstar` (cutoff variety), `y` (output), `h` (aggregate labour), `u` (unemployment rate), `w` (real wage), `ii` (nominal interest rate), `pi` (price inflation), `piW` (wage inflation), `mu` (monetary policy shock), `a` (technology shock).
- **Structural equations:** production function, Euler equation, labour demand, Taylor rule, wage–price inflation identity, cutoff variety condition (eq. 27), wage aggregation (eq. 17), unemployment (eq. 28), and two AR(1) shock processes.
- **Closed-form integrals** are computed as model-local variables (`#` notation) for efficiency: `INT17` (wage aggregation), `INT_s` (labour supply integral), `INT_d` (labour demand integral).
- Calibration follows **Table 1** of the paper: β = 0.99, σ = 1 (log utility), θ = 5 (Frisch), α = 0.75 (labour share), η = 11, Γ₀ = 0.978, Γ₁ = 0.031, π* = 3% annual, uⁿ = 4%.
- Produces **IRFs for 20 quarters** to monetary and technology shocks.

#### `hdnwr_steadystate.m`
Companion steady-state solver called automatically by Dynare (named to match `hdnwr.mod`).

- Uses `fzero` to solve equation (17) numerically for the cutoff variety `jstar` at the steady state.
- Computes all remaining steady-state values analytically from `jstar`.
- Verified steady state: `jstar ≈ 0.6503`, `u ≈ 5.96%`, `pi = piW ≈ 0.74%` quarterly.

#### `hdnwr_nl.mod`
Identical model to `hdnwr.mod` but solved at **second order** (`order=2`) with a long stochastic simulation (`periods=10000`, `pruning`). Used exclusively for nonlinearity visualisation (Approaches 2 and 3 below).

#### `hdnwr_nl_steadystate.m`
Identical to `hdnwr_steadystate.m`, named to match `hdnwr_nl.mod` per Dynare convention.

---

### Visualisation Scripts

Three complementary approaches are provided to visualise the nonlinear Phillips curve. First-order (`order=1`) perturbation cannot reveal nonlinearity; these scripts use exact algebraic evaluation or second-order simulations.

#### `plot_phillips_curve.m` — Approach 1: Static Phillips Curve
Traces equations (17) and (28) **parametrically** over a grid of 2,000 `jstar` values to plot the exact nonlinear (u, πᵂ) locus. No Dynare run required.

- Overlays the **linear tangent** at the steady state for comparison.
- **Output:** `fig_phillips_curve.pdf`

#### `plot_asymmetric_irfs.m` — Approach 2: Asymmetric IRFs
Runs `dynare hdnwr_nl` (order = 2) and then uses `simult_()` to compute paths for a **+1σ monetary shock** (contractionary) and a **−1σ monetary shock** (expansionary) from the deterministic steady state.

- At order = 1 the IRFs are exact mirror images; at order = 2 they differ, revealing the curvature of the Phillips curve (unemployment rises more from the contractionary shock than it falls from the expansionary shock).
- Three panels: unemployment (`u`), wage inflation (`piW`), output (`y`).
- **Output:** `fig_asymmetric_irfs.pdf`

#### `plot_stochastic_scatter.m` — Approach 3: Stochastic Simulation Scatter
Extracts 10,000 simulated (uₜ, πᵂₜ) pairs from `oo_.endo_simul` (requires `hdnwr_nl` to have been run) and scatter-plots them against the theoretical nonlinear Phillips curve locus.

- Can be run in the same MATLAB session as `plot_asymmetric_irfs.m` (reuses `M_`, `oo_`).
- **Output:** `fig_stochastic_scatter.pdf`

---

### Generated Figures

| File | Description |
|------|-------------|
| `fig_phillips_curve.pdf` | Nonlinear wage Phillips curve with linear approximation overlay and steady-state point |
| `fig_asymmetric_irfs.pdf` | Three-panel figure showing asymmetric responses of u, πᵂ, and y to ±1σ monetary shocks |
| `fig_stochastic_scatter.pdf` | 10,000-period scatter of (u, πᵂ) vs the theoretical nonlinear locus |

---

### Dynare Output Folders

#### `hdnwr/`
Dynare working directory for the first-order run. Auto-generated by `dynare hdnwr`.
- `Output/hdnwr_results.mat` — MATLAB results file (steady state, IRFs, model matrices).
- `graphs/` — Auto-generated IRF plots (`hdnwr_IRF_eps_a.eps`, `hdnwr_IRF_eps_mu.eps`).
- `model/bytecode/` — Compiled bytecode files (auto-generated, do not edit).

#### `hdnwr_nl/`
Dynare working directory for the second-order run. Auto-generated by `dynare hdnwr_nl`.
- `Output/hdnwr_nl_results.mat` — MATLAB results file including stochastic simulation output.
- `graphs/` — Auto-generated IRF plots.
- `model/bytecode/` — Compiled bytecode files.

---

### Documentation and Reference

| File | Description |
|------|-------------|
| `sgu_paper_summary.md` | Detailed summary of the paper covering the model setup, HDNWR mechanism, Phillips curve derivation, empirical evidence, extensions, and comparison with Benigno–Eggertsson (2023) |
| `schmittgrohe_uribe_ocr.md` | OCR-extracted text from the working paper |
| `changes_summary.md` | Replication log documenting the creation and validation of the model files |
| `Schmitt-Grohe and Uribe (2025 wp).pdf` | Original working paper (also stored in `readings/`) |
| `readings/` | Subfolder containing a copy of the paper PDF and the paper summary |

---

## How to Replicate

Software requirements: **MATLAB** and **Dynare 6.x**.

### Step 1 — First-order linear model

```matlab
% From the Schmitt-Grohe and Uribe (2025)/ directory:
dynare hdnwr
```

This solves the steady state, checks Blanchard–Kahn conditions, and computes first-order IRFs for 20 quarters. Results are saved to `hdnwr/Output/hdnwr_results.mat`.

### Step 2 — Visualise the nonlinear Phillips curve

**Approach 1 (static, no Dynare needed):**
```matlab
run plot_phillips_curve.m
% Output: fig_phillips_curve.pdf
```

**Approaches 2 and 3 (require second-order Dynare run):**
```matlab
% Approach 2 — Asymmetric IRFs (also runs dynare hdnwr_nl internally):
run plot_asymmetric_irfs.m
% Output: fig_asymmetric_irfs.pdf

% Approach 3 — Stochastic scatter (reuses M_, oo_ from Approach 2):
run plot_stochastic_scatter.m
% Output: fig_stochastic_scatter.pdf
```

---

## Key Model Results

| Variable | Steady-state value |
|----------|--------------------|
| Cutoff variety `jstar` | ≈ 0.6503 (65% of varieties unconstrained) |
| Unemployment `u` | ≈ 5.96% |
| Natural unemployment `uⁿ` | 4.00% |
| Price / wage inflation `pi`, `piW` | ≈ 0.74% quarterly (3% annual) |

**Phillips curve nonlinearity:** Reducing annual wage inflation from 6% to 5% costs approximately 0.3 pp of unemployment, while reducing it from 2% to 1% costs approximately 3.0 pp — a factor of 10 difference, arising from the convexity of the curve.

---

## Model Calibration (Table 1)

| Parameter | Value | Description |
|-----------|-------|-------------|
| β | 0.99 | Discount factor |
| σ | 1 | CRRA (log utility) |
| θ | 5 | Inverse Frisch elasticity |
| α | 0.75 | Labour elasticity of output |
| η | 11 | Elasticity of substitution across labour varieties |
| Γ₀ | 0.978 | Wage lower bound intercept |
| Γ₁ | 0.031 | Wage lower bound slope |
| δ | 1 | Wage indexation to steady-state inflation |
| π* | 0.74% quarterly | Inflation target (3% annual) |
| uⁿ | 4% | Natural rate of unemployment |
| α_π | 1.5 | Taylor rule: inflation response |
| α_y | 0.125 | Taylor rule: output gap response (= 0.5/4) |
| ρ_μ | 0.5 | Monetary shock persistence |
| ρ_a | 0.9 | Technology shock persistence |
