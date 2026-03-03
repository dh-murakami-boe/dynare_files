# Replication log files

## 2026-03-02: Recalibrate twist model — y_low = −0.002, slopes × 0.7

### Motivation
Moved the twist model's kink from y_low = −0.02 (deep recession) to y_low = −0.002 (−0.2% output gap). This makes the "missing disinflation" mechanism operative even in mild recessions. Also flattened the reference-regime slope by 0.7×.

### Parameter changes
| Parameter | Old | New | Notes |
|-----------|-----|-----|-------|
| `kappa_normal` | 0.0490 | 0.0343 | 0.0490 × 0.7 |
| `kappa_v_normal` | 0.0447 | 0.03129 | 0.0447 × 0.7 |
| `y_low` | −0.02 | −0.002 | Threshold moved closer to potential |
| `c_wnb` | −0.000960 | −0.0000666 | Auto-computed: (0.0343 − 0.0010) × (−0.002) |
| `kappa_flat`, `kappa_v_flat` | unchanged | unchanged | |

### Scenario shock recalibration
| Scenario | Old shock | New shock |
|----------|-----------|-----------|
| N | eps_d = −0.015 | eps_d = −0.003 |
| P | eps_d = +0.03 | eps_d = +0.03 (unchanged) |
| R | eps_d = −0.07 | eps_d = −0.03 |
| S | eps_d = −0.05, eps_s = +0.01 | eps_d = −0.03, eps_s = +0.01 |

### Verification results
- **BK conditions**: 3 eigenvalues > 1 for 3 forward-looking variables. ✓
- **Scenario N** (eps_d = −0.003): y(1) = −0.136%, above y_low = −0.2%. Non-binding. ✓
- **Scenario P** (eps_d = +0.03): y(1) = +1.363%, non-binding. ✓
- **Scenario R** (eps_d = −0.03): y(1) = −2.037%, below y_low. Binding. ✓
  - Missing disinflation: pi piecewise = −0.40 pp vs linear = −0.94 pp → gap = **0.54 pp annualized**
- **Scenario S** (eps_d = −0.03, eps_s = +0.01): y(1) = −2.167%, binding. ✓
  - Supply pass-through: 0.03 pp piecewise vs 0.28 pp linear (~88% suppression)
- Figures regenerated: `fig_twist_recession_comparison.pdf`, `fig_twist_as_curve_comparison.pdf`. ✓

### Files modified
- `be_twist.mod`: parameter values, shock sizes, all comments/fprintf updated
- `run_be_twist.m`: sgtitle, fprintf labels, Figure 2 axis ranges and annotation positions
- Fixed pre-existing bug: sgtitle said "eps_d=-0.05" for Scenario R but .mod used −0.07

---

## 2026-03-02: Structural twist model + terminology cleanup

### Terminology fix: "DNWR" → "wage norm binding"
- Replaced all ~50 references to "DNWR" / "Downward Nominal Wage Rigidity" in `be_twist.mod`, `run_be_twist.m`, and this file
- The BE framework does NOT feature strict DNWR; the mechanism is the max(w^ex, w^flex) operator where the existing-wage norm w^ex binds as a floor on w^new when tightness falls below threshold
- Parameter `c_dnwr` → `c_wnb`, OccBin constraint `'dnwr_binding'` → `'wage_norm_binding'`

### Twist model verification (`be_twist.mod`)
- Re-run in MATLAB R2025b + Dynare 6.5 after terminology rename. All results unchanged.
- **BK conditions**: 3 eigenvalues > 1 for 3 forward-looking variables. ✓
- **Scenario N** (eps_d = −0.015): y(1) = −0.553%, non-binding. ✓
- **Scenario P** (eps_d = +0.03): y(1) = +1.105%, non-binding. ✓
- **Scenario R** (eps_d = −0.07): y(1) = −2.673%, wage norm binding triggers. Missing disinflation = 0.12 pp annualized. ✓
- **Scenario S** (eps_d = −0.05, eps_s = +0.01): Supply pass-through reduced under wage norm binding (0.83 pp vs 1.05 pp linear). ✓
- Figures: `fig_twist_recession_comparison.pdf`, `fig_twist_as_curve_comparison.pdf`. ✓

### Structural twist model — new files
- `be_structural_twist.mod` — Dynare 6.5 / OccBin. Inverts the original structural model's nonlinearity: in normal times wages are flexible (w_new = w_flex); in deep recessions (θ < θ_low = −0.05) the wage norm binds (w_new = w_ex), flattening the Phillips curve.
- `be_structural_twist_steadystate.m` — External steady-state file (all zeros).
- `run_be_structural_twist.m` — MATLAB driver: runs Dynare, produces 4 figures.

### Structural twist model specification
- **18 equations**: Same 10 structural + 8 AR(1) as `be_structural.mod`
- **Key difference**: Only the new-hire wage equation changes between regimes:
  - Normal (reference, θ ≥ θ_low): w_new = w_flex (flexible wages)
  - Deep recession (binding, θ < θ_low): w_new = w_ex (wage norm pins wages)
- **OccBin constraint**: `bind theta < theta_low; relax theta >= theta_low;` with θ_low = −0.05
- All other equations identical to `be_structural.mod`

### Structural twist verification results
- **BK conditions**: 3 eigenvalues > 1 for 3 forward-looking variables. Eigenvalue spectrum: 0.172, 0.5, 0.8×7, 1.053±0.207i, 8.9e16. ✓

| Scenario | Shocks | y(1) | π(1) ann. | θ(1) | Regime |
|----------|--------|------|-----------|------|--------|
| 1. Small neg demand | eps_g = −0.02 | −0.87% | −0.73 pp | −0.043 | Non-binding |
| 2. Positive demand | eps_g = +0.05 | +2.17% | +1.83 pp | +0.109 | Non-binding |
| 3. Markup | eps_mu = +0.01 | −0.60% | +0.29 pp | −0.029 | Non-binding |
| 4. Oil price | eps_q = +0.10 | −0.60% | +0.29 pp | −0.029 | Non-binding |
| 5. Large recession | eps_g = −0.05 | −2.42% | −1.51 pp | −0.123 | **Binding** |
| 6. Recession + markup | eps_g = −0.05, eps_mu = +0.01 | −3.04% | −1.19 pp | −0.154 | **Binding** |

- **Missing disinflation** (Scenario 5): piecewise π = −1.51 pp vs linear π = −1.83 pp. Gap = 0.32 pp annualized. ✓
- **Supply pass-through under wage norm binding** (Scenario 6 vs 5): markup adds +0.32 pp (piecewise) vs +0.29 pp (linear) — slightly amplified, not dampened. This is because in the structural model the markup shock enters the Phillips curve directly (through μ̂), not through the wage channel.
- Markup and oil IRFs identical in non-binding regime (same mechanism as `be_structural.mod`).
- Figures: `fig_structural_twist_demand_asymmetry.pdf`, `fig_structural_twist_supply.pdf`, `fig_structural_twist_as_curve.pdf`, `fig_structural_twist_missing_disinfl.pdf`. ✓

### Lessons learned
1. **OccBin variable naming mismatch**: The .mod file's verbatim blocks stored results as `results_pos_demand` while the MATLAB driver expected `results_pos`. Always verify struct names match between .mod verbatim blocks and the driver script.
2. **Twist regime inversion is clean**: Swapping the relax/bind equations for w_new and inverting the OccBin constraint direction (θ > θ\* → θ < θ_low) is sufficient. No other equations need modification. The nonlinearity enters entirely through the wage channel.
3. **θ_low = −0.05 works well**: With eps_g = −0.05, θ(1) = −0.123, well below the threshold. The binding regime produces visible missing disinflation (0.32 pp). No convergence issues.

---

## 2026-02-27: Full structural model implementation

### Files created
- `be_structural.mod` — Dynare 6.5 / OccBin implementation of the full structural model from Sections 3–4 of BE (2025), with search-and-matching labor market, piecewise wage setting, and Rotemberg pricing.
- `be_structural_steadystate.m` — External steady-state file (all zeros, model in log-deviations).
- `run_be_structural.m` — MATLAB driver: runs Dynare, produces 4 figures (demand asymmetry, labor market shocks, supply shocks, static Inverse-L AS-AD diagram).

### Model specification
- **10 endogenous variables**: π, Y, i, θ, w^new, w^ex, w^flex, N, F, u
- **8 primitive shock processes** (AR(1)): productivity (A), markup (μ), oil price (q), demand (g), monetary (e), participation (χ), separation (s), matching efficiency (m)
- **Total: 18 equations** (10 structural + 8 shock AR(1))

#### Structural equations
1. **Phillips curve** (eq. E.22): π = Φ(μ̂ + αŵ^new − Â + (1−α)q̂) + βE_tπ_{t+1}, where Φ ≡ (ε−1)/ς = 0.04
2. **Flexible wage** (eq. E.23): ŵ^flex = ηθ̂ − m̂
3. **New hire wage** (eq. 43, piecewise via OccBin): slack: ŵ^new = ŵ^ex; tight: ŵ^new = ŵ^flex
4. **Existing wage evolution** (eq. 39, log-linearized): ŵ^ex = λ(ŵ^ex_{−1} − π + δE_tπ_{t+1}) + (1−λ)ŵ^flex
5. **Unemployment** (eq. F.28): û = ŝ − z_u(m̂ + (1−η)θ̂)
6. **Employment-participation** (eq. F.27): N̂ = F̂ − (ū/(1−ū))û
7. **Participation** (eq. F.26): ωF̂ + χ̂ = c_{1s}ŵ^ex + c_{su}ŵ^new − c_uû
8. **Production** (eq. F.31): N̂ = (1/α)(Ŷ − Â)
9. **IS curve** (eq. 47): Ŷ − ĝ = E_t(Ŷ_{t+1} − ĝ_{t+1}) − σ^{−1}(î − E_tπ_{t+1})
10. **Taylor rule** (eq. 49): î = φ_ππ + ê

#### Key design choices
- **OccBin constraint on θ > θ\***: Uses θ̂ > θ\_star = 0.01 (log-deviation of tightness). This is cleaner than the simplified model's y > y\_star proxy and directly captures the paper's structural threshold. The nonzero threshold provides a convergence buffer (see lessons below).
- **Phillips curve is single equation**: The nonlinearity arises entirely through the piecewise wage equation (w^new switches between w^ex and w^flex). The PC itself is the same in both regimes — it just uses w_new, which changes.
- **Continuity at the kink**: With the linearization at the kink point, both regimes give w_new = 0 at steady state. No explicit continuity constant needed (unlike the simplified model's c̃).
- **Φ = 0.04**: Calibrated as (ε−1)/ς with ε ≈ 10, ς ≈ 225. This approximately targets the Table B tight-regime slope when mapped through the labor market block.
- **γ^c, γ^b, φ shocks omitted**: These enter only through the composite matching/wage shock ϑ̂. Can be added later for channel decomposition.

### Calibration (Table A)
σ = 0.5, φ_π = 1.5, η = 0.4, ū = 0.04, s̄ = 0.0723, α = 0.9, ω = 1, λ = 0.5, β = 0.99, δ = 1, Φ = 0.04, θ\* = 0.01. Shock persistence ρ = 0.8 (except ρ_e = 0.5).

### Verification results
- **BK conditions**: 3 eigenvalue(s) > 1 for 3 forward-looking variables. Rank condition verified.
- **Steady state**: All zeros. ✓
- **Eigenvalue spectrum**: 0.045, 0.5, 0.8×7, 1.061±0.19i, 8.9e16. The very small eigenvalue (0.045) reflects the near-static nature of the labor market block.

#### OccBin scenario results (impact period, t=1):

| Scenario | ε_g | ε_mu | ε_q | ε_m | ε_s | y(1) | π(1) | θ(1) | u(1) |
|----------|-----|------|-----|-----|-----|------|------|------|------|
| Positive demand | 0.05 | | | | | 0.0215 | 0.0045 | 0.1073 | −0.0288 |
| Negative demand | −0.05 | | | | | −0.0220 | −0.0040 | −0.1116 | 0.0299 |
| Markup | | 0.01 | | | | −0.0059 | 0.0009 | −0.0291 | 0.0078 |
| Oil price | | | 0.10 | | | −0.0059 | 0.0009 | −0.0291 | 0.0078 |
| Matching eff. | | | | −0.05 | | −0.0023 | 0.0001 | −0.1157 | 0.0533 |
| Separation | | | | | 0.01 | −0.0004 | 0.0000 | 0.0017 | 0.0096 |

- Positive demand shock triggers tight regime: θ(1) = 0.107 > θ\* = 0.01. ✓
- Negative demand stays in slack. ✓
- Supply shocks (markup, oil) stay in slack — cost-push with flat PC pass-through. ✓
- Matching efficiency shock: large θ drop (−11.6%), unemployment surge (+5.3%), small output effect (−0.23%). ✓
- Markup and oil IRFs identical: coincidence of effective cost-push impact (Φ×0.01 = Φ(1−α)×0.10 = 0.0004).

### Comparison to simplified model
- Positive demand: structural y(1) = 0.0215 vs simplified y(1) = 0.0253; π(1) nearly identical (0.0045 vs 0.0046).
- The structural model channels demand through the labor market (θ → wages → marginal cost → π), producing slightly less output amplification but similar inflation dynamics.
- The static AS curve shows the characteristic Inverse-L shape, with a smoother kink than the simplified model's sharp break.

### Lessons learned

1. **OccBin constraint must avoid exact kink**: Using `theta > 0` (threshold at exact kink) caused convergence failure for ALL binding scenarios. Switching to `theta > theta_star` with theta_star = 0.01 (a small positive buffer) resolved this. The simplified model's `y > y_star = 0.01` works for the same reason.
2. **OccBin constraint on wage comparison fails**: The "natural" constraint `w_flex - w_ex > 0` also caused convergence failure because w_ex depends on pi(+1) via the wage evolution equation, creating circularity in the constraint evaluation.
3. **Variable naming**: MATLAB interprets `theta` as a toolbox function (Sensor Fusion / Navigation). Use `theta_val`, `th_val` etc. in MATLAB scripts.
4. **Scenario ordering matters (confirmed)**: Non-binding scenarios must run before binding scenarios due to OccBin persistent variable contamination.
5. **Separation rate shock near boundary**: eps_s = 0.02 caused OccBin non-convergence; reduced to 0.01 which works.

### Known issues / next steps
- Φ = 0.04 is a rough calibration. The exact mapping from θ-based coefficients to the Table B Y-based coefficients involves the full Appendix F algebra (z_θ, z̄_θ terms). Refining Φ requires matching at least one Table B moment precisely.
- The 3rd forward-looking variable (beyond π and y) arises from the w_ex evolution equation containing pi(+1). This is correct but unexpected — the simplified model has only 3 forward-looking variables (y, π, i) while the structural model's BK condition counts 3 as well despite having more variables.
- The static AS curve computation uses a fixed-point iteration (pi and the labor market block are coupled). This converges quickly (< 10 iterations) but could be replaced with an analytical solution.
- γ^c, γ^b, φ shocks not yet included. Adding them would enable full decomposition of the composite ϑ̂ channel.
- Combined demand + supply shock scenario not yet attempted (likely to face the same OccBin convergence issues as the simplified model).

---

## 2026-02-27: Twist extension — mirror-image wage norm nonlinear Phillips curve

### Files created
- `be_twist.mod` — Dynare 6.5 / OccBin implementation of the "twist" on BE (2025): a mirror-image nonlinear Phillips curve where the wage norm binds in deep recessions ($y < y_{low} = -0.02$) rather than in booms.
- `run_be_twist.m` — MATLAB driver: runs Dynare, produces Figure 1 (IRF comparison small vs. large recession) and Figure 2 (static AS curve: twist kink vs. BE Inverse-L reference).

### Model specification
- **IS curve and Taylor rule**: identical to `be_simplified.mod` (eqs. 47, 49).
- **Phillips curve**: piecewise with two regimes keyed on $y < y_{low}$:
  - Reference regime ($y >= y_{low}$, unconstrained): $\pi = \kappa_{normal}*(y + \alpha/\omega*\chi) + \kappa_{v_{normal}}*\nu + \pi(+1)$, $\kappa_{normal}=0.0490$, $\kappa_{v_{normal}}=0.0447$
  - Constrained regime ($y < y_{low}$, wage norm binding): $\pi = c_{wnb} + \kappa_{flat}*(y + \alpha/\omega*\chi) + \kappa_{v_{flat}}*\nu + \pi(+1)$, $\kappa_{flat}=0.0010$, $\kappa_{v_{flat}}=0.0005$
- **Threshold**: $y_{low} = -0.02$ (deep recession, -2% output gap)
- **Continuity condition**: $c_{wnb} = (\kappa_{normal} - \kappa_{flat})*y_{low} = (0.0490-0.0010)*(-0.02) = -0.000960$ (negative by construction)
- **OccBin constraint**: `bind y < y_low` / `relax y >= y_low`
- **Shocks**: same 4 AR(1) processes, same persistence parameters as be_simplified.mod

### Scenarios
1. N: eps_d = -0.015 (small recession, non-binding, reference check)
2. P: eps_d = +0.03 (positive demand, reference regime throughout)
3. R: eps_d = -0.07 (large recession, wage norm binding, missing disinflation; note: -0.05 gives y(1)=-0.018 just above threshold, so -0.07 used to ensure binding)
4. S: eps_d = -0.05 + eps_s = +0.01 (recession + supply shock, tests flat supply pass-through)

### Key design choices
- kappa_normal from BE Table B col. 1 (1960-2023 sample, kappa^tight = 0.0490); used as "normal" slope because the twist nonlinearity is in the opposite direction.
- kappa_flat = 0.0010 chosen to be near-zero (wage norm fully pins wages in deep recession).
- kappa_v_flat = 0.0005: supply shocks also have near-zero pass-through when wages floored.
- Supply shock in Scenario S kept at 0.01 (following be_simplified.mod precedent) to avoid OccBin convergence issues from the large kappa_v ratio (0.0447/0.0005 = 89).

### Status
- Files written and reviewed. Terminology updated 2026-03-02: replaced "DNWR" with "wage norm binding" throughout.

---

## 2026-02-27: Verification run, summary corrections, and feasibility assessment

### Verification of `be_simplified.mod`

Model re-run in MATLAB R2025b + Dynare 6.5 to confirm continued correctness. All checks pass:

- **BK conditions**: 3 eigenvalues outside unit circle for 3 forward-looking variables (y, π, i). Rank condition verified.
- **Steady state**: All zeros. ✓
- **Scenario A**: y(1) = 0.025280, π(1) = 0.004584 — output gap exceeds Y\* = 0.01, tight regime engages, inflation amplified. ✓
- **All four OccBin scenarios** complete without errors. Figures saved to current directory. ✓

Model specification confirmed correct vs. paper equations 47–49. See detailed comparison in plan file.

### Corrections to `be_paper_summary.md`

1. **Fixed broken Taylor rule LaTeX** (Section 4, Closing): asterisks in `\hat{r}*t^e` and `\phi*\pi` were parsed as markdown bold markers, garbling the equation. Corrected to: $\hat{i}_t = \rho\hat{r}_t^e + \phi_\pi(\pi_t - \pi^*) + e_t$.
2. **Added $\kappa_v$ sign-convention note** (Section 3): Table B (2008–2023) reports $\tilde{\kappa}_v = -0.0093$ but the structural sign is positive. The `.mod` file correctly uses $+0.0093$. The negative empirical estimate reflects the 2008–2023 sample composition.

---

### Feasibility Assessment: Full Structural BE Model

**Verdict: HIGH feasibility.** The full structural model can be implemented in Dynare 6.5 + OccBin with moderate effort. Key details below.

#### Blocks and variables to add (beyond simplified 3-equation)

| Block | New endogenous variables | New equations | Difficulty |
|-------|--------------------------|---------------|------------|
| Household (GHH) | $C_t$, $F_t$ (labor force), $X_t$ (GHH composite) | Euler (eq. 14), participation FOC (eq. 13), goods clearing | Low |
| Labor market | $U_t$ (unemployment), $V_t$ (vacancies), $\theta_t = V_t/U_t$ | Matching (eq. 10), Beveridge curve (eqs. 56–58), employment law of motion | Medium |
| Employment agencies | $w_t^{flex}$ | Zero-profit condition → flexible wage (eq. 33) | Low |
| Wage dynamics | $w_t^{ex}$ (wage norm, state), $w_t^{new}$ | Wage norm evolution (eq. 39), piecewise wage rule (eq. 40) via OccBin | **Medium** |
| Firms | $MC_t$, $O_t$ (intermediate input) | Production (eq. 17), oil demand FOC, Rotemberg pricing (eq. 23) | Low |
| Shocks | $\hat{m}_t$, $\hat{s}_t$, $\hat{q}_t$, $\hat{A}_t$ | AR(1) processes for 4 additional shocks | Low |

Approximate size: **20–22 endogenous variables, ~18 equations, 7–8 shocks.**

#### Why feasibility is high
1. The model is log-linearized around a zero-inflation steady state — all equations in Section 4 of the paper are already in log-linear form, ready for Dynare.
2. The single nonlinearity (max operator in $w_t^{new}$) is already handled by OccBin in the simplified model. The full model simply replaces the output gap proxy $y > y^*$ with the structural tightness condition $\hat{\theta}_t > \hat{\theta}_t^*$, which is cleaner.
3. The search-and-matching block (matching function, Beveridge curve, employment agencies) is standard in the Dynare/macro-labor literature with many existing examples.
4. Rotemberg pricing is computationally simpler than Calvo and delivers an identical first-order approximation.

#### Key challenges
1. **OccBin constraint in terms of $\hat{\theta}_t$**: The full model allows the threshold to be expressed directly as $\hat{\theta}_t > 0$ (log-deviation of tightness above steady state $\theta^* = 1$), which eliminates the approximate $y^* = 0.01$ calibration.
2. **Wage norm state variable**: $w_t^{ex}$ appears with both a lag ($w_{t-1}^{ex}$) and in expectational terms ($E_t\pi_{t+1}$). Steady-state calibration requires $w^{ex} = w^{flex}$ (by construction at the kink point). Log-linearization of eq. 39 around this steady state is straightforward but must be done carefully.
3. **Dynamic Beveridge curve**: Equation (58) for $\theta_t$ requires tracking both $s_t$ (separation rate, time-varying shock) and $m_t$ (matching efficiency shock). These add two state variables.
4. **OccBin stability**: The 30× discontinuity in $\kappa_v^{tight}/\kappa_v$ (0.0093 → 0.2742) already causes oscillation in the simplified model. This may be larger in the full model; addressing it may require reducing shock sizes or switching to a perturbation-based approach for stochastic analysis.

#### Recommended implementation sequence
1. **Phase 1** (next session): Add $w_t^{ex}$ state variable and piecewise wage rule to simplified model. Use $\hat{\theta}_t$ directly for OccBin constraint. This gives the correct model dynamics near the kink.
2. **Phase 2**: Add labor market block ($U_t$, $V_t$, $\theta_t$, $F_t$, matching function, Beveridge curve). This allows structural calibration of $\theta^*$ and the regime threshold.
3. **Phase 3**: Add intermediate input ($O_t$, $q_t$) and the full GHH household block. Add matching efficiency ($\hat{m}_t$), separation rate ($\hat{s}_t$), and TFP ($\hat{A}_t$) shocks.
4. **Validation**: Check each phase against BE Figures 8–11 (Inv-L curve, AS-AD diagrams for 2020s, 1970s, 2008 episodes).

---

## 2026-02-24: Initial implementation of simplified 3-equation policy model

### Files created
- `be_simplified.mod` — Dynare 6.5 / OccBin model file implementing the simplified 3-equation policy model (equations 47-49) from Benigno & Eggertsson (2025).
- `run_be_simplified.m` — MATLAB driver script for running simulations, generating OccBin IRFs, and plotting AS-AD diagrams.

### Model specification
- **IS curve** (eq. 47): Standard New Keynesian Euler equation with demand shocks.
- **Phillips curve** (eq. 48): Piecewise-linear with two regimes:
  - Slack regime (Y ≤ Y*): flat, κ = 0.0065, κ_ν = 0.0093
  - Tight regime (Y > Y*): steep, κ_tight = 0.0736, κ_ν_tight = 0.2742
  - Coefficients from Table B, column 2 (2008-2023 sample)
- **Taylor rule** (eq. 49): φ_π = 1.5.
- **OccBin constraint**: Regime switches when output gap exceeds Y* threshold.
- **Shocks**: AR(1) processes for demand (g), supply (ν), monetary policy (e), and labor participation (χ). Persistence ρ = 0.8 (matching τ from paper).
- **Calibration**: Table A structural parameters (σ=0.5, β=0.99, etc.). Y* = 0.01 as starting value.

### Simulation scenarios in driver script
1. Positive demand shock (tests nonlinear amplification)
2. Supply shock (tests regime-dependent pass-through)
3. Combined demand + supply (2020s replication, Figure 9)
4. Negative demand shock (asymmetry comparison)
5. Static AS-AD diagrams (Figures 8-9 replicas)

### Status
- **Working in MATLAB R2025b + Dynare 6.5.** All four OccBin scenarios and plots complete successfully.
- Verified output: Scenario A demand shock gives y(1) = 0.025531, pi(1) = 0.004540.

### OccBin lessons learned (Dynare 6.5)
- **Shock syntax**: Use `shocks(surprise, overwrite)` with `var`/`periods`/`values` keywords. Must call `occbin_setup(simul_periods=N)` AFTER the `shocks` block (not before — `occbin_setup` reads the shock specification).
- **Scenario ordering matters**: `occbin.solver` uses persistent variables that cache decision rules. Non-binding scenarios (supply shock, negative demand) must run BEFORE binding scenarios (positive demand) to avoid contamination.
- **Combined shock convergence**: The 30x discontinuity in κ_ν at the regime boundary (0.0093 → 0.2742) causes OccBin to oscillate when both demand and supply shocks are present. Supply shock in Scenario C reduced to 0.001 to achieve convergence. The static AS-AD analysis handles arbitrary supply shock sizes without this limitation.
- **Results stored in** `oo_.occbin.simul.piecewise` (T×7 matrix, no extra SS row) and `oo_.occbin.simul.linear`.

### Known issues / next steps
- Y* calibration is approximate (0.01). Needs mapping from θ* = 1 via structural model.
- Shock standard deviations are initial guesses; need calibration to match 2020s magnitudes.
- Supply shock coefficient κ_ν = -0.0093 in the paper's Table B (2008-2023) is negative; we use the absolute value. This should be revisited.
- Combined shock (Scenario C) limited to small supply shock (0.001) due to OccBin convergence; larger supply shocks cause regime oscillation.
- Future work: implement the full structural model with search-and-matching labor market.