// =========================================================================
// "Twist" on Benigno and Eggertsson (2025): Mirror-Image Nonlinear PC
// with Wage Norm Binding in Deep Recessions
//
// Implementation using Dynare 6.5 OccBin toolkit
// Author:  David Murakami
// Date:    2026-02-27
//
// Reference: Benigno, P. and Eggertsson, G. (2025)
//   "It's Baaack: The Surge in Inflation"
//
// MODEL OVERVIEW:
//   The BE (2025) paper documents an Inverse-L Phillips curve: flat in
//   normal/slack times (theta <= theta*) and steep in tight labor markets
//   (theta > theta*). This "twist" model implements the mirror-image
//   nonlinearity motivated by wage norm rigidity:
//
//   REFERENCE REGIME (unconstrained, y >= y_low):
//     The wage norm constraint w^new = max{w^ex, w^flex} is non-binding because
//     the flexible wage exceeds or equals the existing-wage norm. Wages
//     adjust normally, and the Phillips curve has a moderate slope
//     kappa_normal (analogous to the tight-regime slope in BE).
//
//   CONSTRAINED REGIME (wage norm binding, y < y_low):
//     In a deep recession, the flexible wage w^flex falls sharply below
//     the existing-wage norm w^ex. The max operator forces w^new = w^ex,
//     so wages are floored at the norm. Marginal cost barely moves in
//     response to falling output, producing a near-zero PC slope kappa_flat.
//
// ECONOMIC MECHANISM (Missing Disinflation):
//   The twist model explains "missing disinflation": when the economy enters
//   a recession with y < y_low = -0.2%, the wage norm pins wages at their
//   norm, severing the output-inflation link and producing a nearly flat
//   Phillips curve in the constrained regime. With y_low = -0.002, this
//   mechanism activates even in mild recessions.
//
// PIECEWISE STRUCTURE (mirror of BE's Inverse-L):
//   BE original:  flat for y <= y*  (slack),  steep for y > y*  (tight)
//   Twist:        normal slope for y >= y_low,  flat for y < y_low (deep recession)
//   This gives a "J"-shaped or "hockey-stick" PC (steep on left, flat on right
//   when reading from recession to boom), i.e., the horizontal segment is at
//   the bottom-left rather than bottom-right of the (y, pi) space.
//
// CONTINUITY CONDITION (analogous to -c_tilde in BE):
//   At y = y_low both regimes must give the same inflation:
//     Reference:   pi = kappa_normal * y_low + kappa_v_normal * nu + pi(+1)
//     Constrained: pi = c_wnb + kappa_flat * y_low + kappa_v_normal * nu + pi(+1)
//   => c_wnb = (kappa_normal - kappa_flat) * y_low
//   Since kappa_normal > kappa_flat > 0 and y_low < 0:  c_wnb < 0.
//   The negative intercept shift in the constrained regime ensures that the
//   flat PC segment begins from the same (y_low, pi_low) kink point.
//
// VARIABLE COUNT CHECK:
//   Endogenous: y, pi, ii, g, nu, e, chi  =>  7 variables
//   Equations in model block: IS (1) + PC (1, regime-dependent) + TR (1)
//                             + 4 AR(1) shock processes = 7 equations
//   BK check: forward-looking variables are y, pi, ii (appear as y(+1), pi(+1))
//             => 3 forward-looking variables; expect 3 eigenvalues outside unit circle.
//   The 3-eq NK model under the Taylor principle (phi_pi > 1) satisfies BK
//   in both regimes (regime-specific coefficient matrices are stable under
//   standard parameterizations).
//
// RELATIONSHIP TO be_simplified.mod:
//   IS curve and Taylor rule are identical to be_simplified.mod (eqs. 47, 49).
//   PC and OccBin constraint are mirror-image.
//   Calibration parameters updated to reflect wage norm twist interpretation.
//
// =========================================================================


// =========================================================================
// VARIABLE DECLARATIONS
// =========================================================================

var
    y       $\hat{Y}$       (long_name='Output gap (log deviation from potential)')
    pi      $\pi$           (long_name='Inflation deviation from target (quarterly)')
    ii      $\hat{i}$       (long_name='Nominal interest rate deviation (quarterly)')
    g       $\hat{g}$       (long_name='Demand shock state (AR1)')
    nu      $\nu$           (long_name='Supply / cost-push shock state (AR1)')
    e       $\hat{e}$       (long_name='Monetary policy shock state (AR1)')
    chi     $\hat{\chi}$    (long_name='Labor participation shock state (AR1)')
;


// =========================================================================
// EXOGENOUS SHOCK DECLARATIONS
// =========================================================================

varexo
    eps_d   $\varepsilon_d$      (long_name='Demand shock innovation (period-1 surprise)')
    eps_s   $\varepsilon_\nu$    (long_name='Supply shock innovation (period-1 surprise)')
    eps_m   $\varepsilon_e$      (long_name='Monetary policy shock innovation (period-1 surprise)')
    eps_chi $\varepsilon_\chi$   (long_name='Labor participation shock innovation (period-1 surprise)')
;


// =========================================================================
// PARAMETER DECLARATIONS
// =========================================================================

parameters
    // --- Structural (IS / Taylor rule) ---
    sigma       $\sigma$
        (long_name='Inverse intertemporal elasticity of substitution')
    phi_pi      $\phi_\pi$
        (long_name='Taylor rule coefficient on inflation')

    // --- Phillips curve: reference regime (unconstrained, y >= y_low) ---
    kappa_normal   $\kappa^{nor}$
        (long_name='PC slope on output gap, normal/reference regime')
    kappa_v_normal $\kappa_\nu^{nor}$
        (long_name='PC coefficient on supply shock, normal/reference regime')

    // --- Phillips curve: constrained regime (wage norm binding, y < y_low) ---
    kappa_flat     $\kappa^{flat}$
        (long_name='PC slope on output gap, constrained/flat regime (near-zero)')
    kappa_v_flat   $\kappa_\nu^{flat}$
        (long_name='PC coefficient on supply shock, constrained/flat regime')

    // --- Regime switch ---
    y_low          $\hat{Y}_{low}$
        (long_name='Output gap threshold for wage norm binding (< 0)')
    c_wnb          $c^{wnb}$
        (long_name='Intercept shift in constrained regime (continuity condition, < 0)')

    // --- Composite labor market parameter ---
    alpha_omega    $\alpha/\omega$
        (long_name='Labor share over inverse Frisch elasticity')

    // --- Shock persistence ---
    rho_g       $\rho_g$        (long_name='Demand shock persistence')
    rho_nu      $\rho_\nu$      (long_name='Supply shock persistence')
    rho_e       $\rho_e$        (long_name='Monetary policy shock persistence')
    rho_chi     $\rho_\chi$     (long_name='Labor participation shock persistence')
;


// =========================================================================
// CALIBRATION
// =========================================================================

// --- Structural parameters (same as be_simplified.mod, Table A of BE 2025) ---
sigma       = 0.5;          // Inverse IES; governs IS slope
phi_pi      = 1.5;          // Taylor principle satisfied (phi_pi > 1)

// --- Normal/reference regime PC slopes ---
// kappa_normal: interpreted as the moderately-steep slope operative when
//   the wage norm constraint is not binding. Scaled to 70% of the
//   1960-2023 sample estimate for kappa^tight from Table B, column 1 of
//   BE (2025) to produce a flatter default-regime AS curve.
//   Table B col. 1 (1960-2023): kappa^tight = 0.0490 × 0.7 = 0.0343
//   (quarterly units, already divided by 400 per Appendix D note).
kappa_normal   = 0.0343;    // Moderate slope; normal times (quarterly)

// kappa_v_normal: supply shock pass-through in normal times.
//   Table B col. 1 (1960-2023): kappa_v = 0.0447 × 0.7 = 0.03129 (quarterly).
kappa_v_normal = 0.03129;   // Normal-regime supply shock coefficient

// --- Constrained/flat regime PC slopes (wage norm binding) ---
// In a deep recession with the wage norm fully binding, wages are floored at w^ex.
// Marginal cost is pinned and barely responds to further output declines.
// The resulting PC slope is near-zero.
kappa_flat     = 0.0010;    // Near-zero slope: wage norm floor pins wages (quarterly)
kappa_v_flat   = 0.0005;    // Near-zero: supply shocks don't pass through
                             //   when wages are floored by the wage norm

// --- Regime threshold ---
// y_low is the output gap level below which the deep-recession / wage-norm-binding
// regime is active. Set at -0.2% (-0.002 in log-deviation units), so the flat
// Phillips curve activates even in mild recessions rather than only in deep
// (2008-magnitude) contractions. This makes the "missing disinflation" mechanism
// operative across a broader range of negative output gaps.
y_low          = -0.002;    // -0.2% threshold (log deviation); negative by construction

// --- Continuity condition (intercept shift in constrained regime) ---
// Derived from: kappa_normal * y_low = c_wnb + kappa_flat * y_low
// => c_wnb = (kappa_normal - kappa_flat) * y_low
// Numerical check: (0.0343 - 0.0010) * (-0.002) = 0.0333 * (-0.002) = -0.0000666
// c_wnb < 0 because kappa_normal > kappa_flat and y_low < 0.
// Interpretation: at the kink point y_low, the constrained regime PC passes
// through the same (y_low, pi) coordinate as the reference regime PC. The
// negative intercept compensates for the shallower slope to the left of y_low.
c_wnb          = (kappa_normal - kappa_flat) * y_low;

// --- Composite labor market parameter (Table A, BE 2025) ---
alpha_omega    = 0.9;       // alpha/omega = 0.9/1.0 = 0.9

// --- Shock persistence (consistent with be_simplified.mod) ---
rho_g       = 0.8;          // Demand; tau = 0.8 in paper's Markov structure
rho_nu      = 0.8;          // Supply
rho_e       = 0.5;          // Monetary policy (less persistent)
rho_chi     = 0.8;          // Labor participation


// =========================================================================
// MODEL EQUATIONS
// =========================================================================
// All variables are log-deviations from the zero-inflation steady state.
// Beta = 1 (footnote 51 of BE): forward inflation enters as pi(+1) with
// coefficient 1, eliminating a long-run output-inflation tradeoff.
// =========================================================================

model;

    // -----------------------------------------------------------------------
    // Eq. 1: IS Curve (eq. 47 of BE 2025)
    // -----------------------------------------------------------------------
    // New Keynesian Euler equation (linearized consumption/savings optimality):
    //   Y_t - G_t = E_t(Y_{t+1} - G_{t+1}) - sigma^{-1} * (i_t - E_t pi_{t+1})
    // G_t is a reduced-form demand shock absorbing both preference shocks and
    // the natural rate. The natural real interest rate r^epsilon is absorbed
    // into g (see BE eq. 47 footnote). Standard: higher real rate lowers output.
    [name='IS curve']
    y - g = y(+1) - g(+1) - (1/sigma) * (ii - pi(+1));

    // -----------------------------------------------------------------------
    // Eq. 2a: Phillips Curve — REFERENCE REGIME (unconstrained, y >= y_low)
    // -----------------------------------------------------------------------
    // When output is above the deep-recession threshold y_low, the wage norm
    // constraint is non-binding: the flexible wage w^flex >= w^ex (existing
    // wage norm), so w^new = w^flex. Wages adjust normally and the PC has
    // a moderate slope kappa_normal (analogous to the tight-regime slope in
    // the original BE Inverse-L structure).
    //
    // PC:  pi_t = kappa_normal * (Y_t + alpha/omega * chi_t)
    //             + kappa_v_normal * nu_t + E_t(pi_{t+1})
    //
    // The (Y + alpha/omega * chi) term captures the effective labor demand
    // shifter: a positive participation shock chi reduces unemployment at
    // given output, reducing marginal cost and hence inflation.
    // (Eq. 48 of BE, reference regime)
    [name='Phillips curve', relax='wage_norm_binding']
    pi = kappa_normal * (y + alpha_omega * chi) + kappa_v_normal * nu + pi(+1);

    // -----------------------------------------------------------------------
    // Eq. 2b: Phillips Curve — CONSTRAINED REGIME (wage norm binding, y < y_low)
    // -----------------------------------------------------------------------
    // In a deep recession (y < y_low), the desired flexible wage w^flex falls
    // well below the existing-wage norm w^ex. The max operator in BE's wage
    // equation forces w^new = w^ex: wages cannot be cut. With wages floored,
    // marginal cost is insensitive to further declines in output demand, so
    // the PC slope collapses to near-zero (kappa_flat ~ 0).
    //
    // This produces "missing disinflation": a large negative output gap
    // (y << 0) generates almost no disinflation because the wage norm floor
    // prevents cost deflation from passing through to prices.
    //
    // The c_wnb intercept shift (< 0) ensures continuity at y = y_low:
    //   c_wnb = (kappa_normal - kappa_flat) * y_low < 0
    // At y = y_low:  c_wnb + kappa_flat * y_low = kappa_normal * y_low  [verified]
    //
    // PC:  pi_t = c_wnb + kappa_flat * (Y_t + alpha/omega * chi_t)
    //             + kappa_v_flat * nu_t + E_t(pi_{t+1})
    //
    // Note: kappa_v_flat << kappa_v_normal because when wages are floored,
    // supply shocks (oil prices, import costs) also have minimal pass-through
    // to final prices — firms cannot raise wages to attract workers but they
    // also cannot compress labor costs, so supply-cost variation is absorbed
    // in margins rather than prices.
    // (Analogous to eq. 48 of BE, but for the twist / constrained regime)
    [name='Phillips curve', bind='wage_norm_binding']
    pi = c_wnb + kappa_flat * (y + alpha_omega * chi) + kappa_v_flat * nu + pi(+1);

    // -----------------------------------------------------------------------
    // Eq. 3: Taylor Rule (eq. 49 of BE 2025)
    // -----------------------------------------------------------------------
    // Simple inflation-targeting rule; monetary policy shock e captures
    // deviations from the rule (r^epsilon absorbed into the policy error).
    // phi_pi = 1.5 > 1 satisfies the Taylor principle in both regimes.
    [name='Taylor rule']
    ii = phi_pi * pi + e;

    // -----------------------------------------------------------------------
    // Shock AR(1) processes
    // -----------------------------------------------------------------------
    // All shocks follow first-order autoregressive processes.
    // Persistence rho = 0.8 matches tau in the paper's Markov structure
    // (two-state Markov chains approximated by AR(1)).

    // Demand shock: g_t = rho_g * g_{t-1} + eps_d_t
    // Captures demand-side shifts (preference, fiscal, foreign demand).
    [name='Demand shock AR(1)']
    g = rho_g * g(-1) + eps_d;

    // Supply / cost-push shock: nu_t = rho_nu * nu_{t-1} + eps_s_t
    // Captures intermediate input cost changes (e.g., oil prices); enters
    // the PC via kappa_v coefficients (regime-dependent pass-through).
    [name='Supply shock AR(1)']
    nu = rho_nu * nu(-1) + eps_s;

    // Monetary policy shock: e_t = rho_e * e_{t-1} + eps_m_t
    // Serially correlated deviations from the Taylor rule.
    [name='Monetary policy shock AR(1)']
    e = rho_e * e(-1) + eps_m;

    // Labor participation shock: chi_t = rho_chi * chi_{t-1} + eps_chi_t
    // Shifts labor force participation, affecting unemployment at given output
    // and thereby influencing marginal cost (via alpha/omega composite).
    [name='Labor participation shock AR(1)']
    chi = rho_chi * chi(-1) + eps_chi;

end;


// =========================================================================
// OCCBIN CONSTRAINT: WAGE NORM BINDING IN DEEP RECESSION
// =========================================================================
// The constraint switches regime based on whether output falls below y_low.
//
// RELAX (reference, normal times): y >= y_low
//   Wage norm non-binding; moderate PC slope kappa_normal operative.
//
// BIND (constrained, deep recession): y < y_low
//   Wage norm fully binding; near-zero PC slope kappa_flat operative.
//   Missing-disinflation mechanism active.
//
// NOTE: In be_simplified.mod the tight regime uses y > y_star (positive
// threshold). Here the deep-recession regime uses y < y_low (negative
// threshold). The sign of the OccBin inequality is reversed relative to
// be_simplified.mod, reflecting the mirror-image nature of the nonlinearity.
//
// Dynare convention: the 'relax' equation (reference regime) MUST appear
// first in the model block. OccBin augments the model with the 'bind'
// equation when the constraint is active.

occbin_constraints;
    name 'wage_norm_binding';
    bind   y < y_low;    // deep recession: wage norm binding, wages floored, flat PC
    relax  y >= y_low;   // normal / moderate times: wage norm non-binding, normal slope PC
end;


// =========================================================================
// STEADY STATE (all zeros: model in log-deviations from zero-inflation SS)
// =========================================================================
// The zero-inflation steady state has y = pi = ii = g = nu = e = chi = 0.
// Verified: all equations hold at zero with any AR(1) persistence parameter.
// The steady state lies in the reference regime (y = 0 > y_low = -0.002).

steady_state_model;
    y   = 0;
    pi  = 0;
    ii  = 0;
    g   = 0;
    nu  = 0;
    e   = 0;
    chi = 0;
end;


// =========================================================================
// STEADY STATE AND BLANCHARD-KAHN CHECK
// =========================================================================
// Expected BK: 3 eigenvalues outside unit circle (for 3 forward-looking
// variables: y appears in IS as y(+1), pi appears in PC as pi(+1) and in
// IS as pi(+1), ii implied forward via Taylor rule).
// phi_pi = 1.5 > 1 ensures determinacy in the reference regime.
// Both regimes share the same IS and Taylor rule; only PC slope differs.
// The flat PC (kappa_flat ~ 0) does not destabilize BK as long as phi_pi > 1.

steady;
check;


// =========================================================================
// OCCBIN SCENARIOS
// =========================================================================
// Scenarios ordered: non-binding first (N, P), then binding (R, S).
// This avoids contamination of OccBin's internal persistent decision-rule
// cache by regime-switching computations (see changes_summary.md).
//
// Shock syntax (Dynare 6.5): shocks(surprise, overwrite) with
// var / periods / values blocks. occbin_setup MUST follow the shock block.
//
// Results stored in verbatim blocks using:
//   oo_.occbin.simul.piecewise  [T x 7 matrix, periods x endogenous variables]
//   oo_.occbin.simul.linear     [T x 7 matrix, linear (no regime switch) counterpart]
// Variable column order matches declaration order: y, pi, ii, g, nu, e, chi.
// =========================================================================


// -------------------------------------------------------------------------
// Scenario N: Small negative demand shock (does NOT trigger wage norm regime)
// -------------------------------------------------------------------------
// eps_d = -0.003 => output gap impact ~-0.1%, stays above y_low = -0.2%.
// Expected: piecewise and linear solutions nearly identical.
// Regime check: y(1) should remain >= y_low = -0.002.

shocks(surprise, overwrite);
    var eps_d;
    periods 1;
    values -0.003;
end;

occbin_setup(simul_periods=20, simul_check_ahead_periods=20);
occbin_solver;

verbatim;
    results_normal_neg.piecewise = oo_.occbin.simul.piecewise;
    results_normal_neg.linear    = oo_.occbin.simul.linear;
    fprintf('\n=== Scenario N (small negative demand, no wage norm regime) completed ===\n');
    if results_normal_neg.piecewise(1,1) >= -0.002
        fprintf('  y(1)  = %.6f  [above y_low = -0.002000: wage norm not triggered, as expected]\n', ...
                results_normal_neg.piecewise(1,1));
    else
        fprintf('  y(1)  = %.6f  [WARNING: below y_low = -0.002000, wage norm triggered unexpectedly]\n', ...
                results_normal_neg.piecewise(1,1));
    end
    fprintf('  pi(1) = %.6f\n', results_normal_neg.piecewise(1,2));
end;


// -------------------------------------------------------------------------
// Scenario P: Positive demand shock (reference regime throughout)
// -------------------------------------------------------------------------
// eps_d = +0.03 => output gap rises; y > 0 >> y_low = -0.2%, firmly non-binding.
// Tests the reference-regime (normal-slope) PC response.
// A positive demand shock raises both output and inflation; the Taylor rule
// raises the nominal rate, dampening the boom over subsequent quarters.

shocks(surprise, overwrite);
    var eps_d;
    periods 1;
    values 0.03;
end;

occbin_setup(simul_periods=20, simul_check_ahead_periods=20);
occbin_solver;

verbatim;
    results_pos.piecewise = oo_.occbin.simul.piecewise;
    results_pos.linear    = oo_.occbin.simul.linear;
    fprintf('\n=== Scenario P (positive demand shock) completed ===\n');
    fprintf('  y(1)  = %.6f\n', results_pos.piecewise(1,1));
    fprintf('  pi(1) = %.6f\n', results_pos.piecewise(1,2));
end;


// -------------------------------------------------------------------------
// Scenario R: Moderate negative demand shock (TRIGGERS wage norm binding regime)
// -------------------------------------------------------------------------
// eps_d = -0.03 => output gap impact well below y_low = -0.2%.
// With the threshold now at -0.002, even moderate negative demand shocks
// push the economy into the constrained regime.
// Expected: wage norm binds on impact; inflation barely falls despite
// output contraction (missing disinflation). Piecewise differs markedly from linear.
//
// Economic story: a moderate recession pushes y below y_low = -0.002.
// In the constrained regime, the near-zero PC slope means pi barely moves
// even as y falls. The linear solution (with kappa_normal slope)
// would predict substantially more disinflation.

shocks(surprise, overwrite);
    var eps_d;
    periods 1;
    values -0.03;
end;

occbin_setup(simul_periods=20, simul_check_ahead_periods=20);
occbin_solver;

verbatim;
    results_recession.piecewise = oo_.occbin.simul.piecewise;
    results_recession.linear    = oo_.occbin.simul.linear;
    fprintf('\n=== Scenario R (moderate recession, wage norm binding) completed ===\n');
    if results_recession.piecewise(1,1) < -0.002
        fprintf('  y(1)  = %.6f  [below y_low = -0.002000: wage norm triggered, as expected]\n', ...
                results_recession.piecewise(1,1));
    else
        fprintf('  y(1)  = %.6f  [WARNING: above y_low = -0.002000, wage norm not triggered]\n', ...
                results_recession.piecewise(1,1));
    end
    fprintf('  pi(1) piecewise = %.6f\n', results_recession.piecewise(1,2));
    fprintf('  pi(1) linear    = %.6f  [missing disinflation: piecewise < linear in magnitude]\n', ...
            results_recession.linear(1,2));
end;


// -------------------------------------------------------------------------
// Scenario S: Moderate recession + supply shock (wage norm binding + cost-push)
// -------------------------------------------------------------------------
// eps_d = -0.03, eps_s = +0.01: moderate demand contraction plus adverse
// supply shock. The Taylor rule's response to the supply-shock inflation
// raises the real rate, deepening the output contraction and pushing y
// below y_low = -0.002. Tests supply-shock pass-through when wage norm binding.
//
// Key prediction: in the constrained regime kappa_v_flat << kappa_v_normal,
// so even with an adverse supply shock, inflation barely responds. The supply
// shock is mostly absorbed in firm margins rather than prices.
// Compare piecewise vs. linear to isolate regime-switching effect on pi.
//
// NOTE: Supply shock magnitude kept modest (0.01) to avoid potential OccBin
// convergence issues at the regime boundary (the ratio kappa_v_normal /
// kappa_v_flat = 0.03129 / 0.0005 ≈ 63 is large; see changes_summary.md for
// analogous convergence challenge in be_simplified.mod).

shocks(surprise, overwrite);
    var eps_d;
    periods 1;
    values -0.03;
    var eps_s;
    periods 1;
    values 0.01;
end;

occbin_setup(simul_periods=20, simul_check_ahead_periods=20);
occbin_solver;

verbatim;
    results_supply_recession.piecewise = oo_.occbin.simul.piecewise;
    results_supply_recession.linear    = oo_.occbin.simul.linear;
    fprintf('\n=== Scenario S (recession + supply shock) completed ===\n');
    fprintf('  y(1)  = %.6f\n', results_supply_recession.piecewise(1,1));
    fprintf('  pi(1) piecewise = %.6f\n', results_supply_recession.piecewise(1,2));
    fprintf('  pi(1) linear    = %.6f\n', results_supply_recession.linear(1,2));
    fprintf('  Supply shock pass-through ratio (pi_S - pi_R) / (pi_S_lin - pi_R_lin):\n');
    fprintf('    Piecewise: %.4f\n', ...
            (results_supply_recession.piecewise(1,2) - results_recession.piecewise(1,2)));
    fprintf('    Linear:    %.4f\n', ...
            (results_supply_recession.linear(1,2) - results_recession.linear(1,2)));
end;
