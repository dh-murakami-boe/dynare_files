// =========================================================================
// Benigno and Eggertsson (2025): Full Structural Model
// with Search-and-Matching Labor Market and Nonlinear Phillips Curve
//
// Implementation using Dynare 6.5 OccBin toolkit
// Author:  David Murakami
// Date:    2026-02-27
// Quarterly frequency
//
// Reference: Benigno, P. and Eggertsson, G. (2025)
// "It's Baaack: The Surge in Inflation"
//
// This model implements the full structural specification from Section 3-4
// of the paper, with:
//   - Rotemberg pricing (eq. E.22)
//   - Search-and-matching labor market
//   - Piecewise wage setting: w_new = max(w_ex, w_flex) via OccBin
//   - Primitive shocks (productivity, markup, oil, demand, monetary,
//     participation, separation, matching efficiency)
//
// The regime switch is on the wage comparison (w_flex vs w_ex) rather
// than the output gap proxy (y > y_star) used in be_simplified.mod.
// =========================================================================

// -------------------------------------------------------------------------
// Variable declarations
// -------------------------------------------------------------------------

var
    // Core macro variables
    pi          $\pi$           (long_name='Inflation deviation from target')
    y           $\hat{Y}$       (long_name='Output gap')
    ii          $\hat{i}$       (long_name='Nominal interest rate deviation')

    // Labor market variables
    theta       $\hat{\theta}$   (long_name='Labor market tightness (log-dev)')
    w_new       $\hat{w}^{new}$ (long_name='New hire real wage (log-dev)')
    w_ex        $\hat{w}^{ex}$  (long_name='Existing worker real wage (log-dev)')
    w_flex      $\hat{w}^{flex}$ (long_name='Flexible/market-clearing wage (log-dev)')
    n_emp       $\hat{N}$       (long_name='Employment (log-dev)')
    f_lf        $\hat{F}$       (long_name='Labor force participation (log-dev)')
    u_rate      $\hat{u}$       (long_name='Unemployment rate (log-dev)')

    // Shock state variables
    a_shock     $\hat{A}$       (long_name='Productivity shock state')
    mu_shock    $\hat{\mu}$     (long_name='Markup shock state')
    q_shock     $\hat{q}$       (long_name='Oil/intermediate input price shock state')
    g_shock     $\hat{g}$       (long_name='Demand shock state')
    e_shock     $\hat{e}$       (long_name='Monetary policy shock state')
    chi_shock   $\hat{\chi}$    (long_name='Labor participation shock state')
    s_shock     $\hat{s}$       (long_name='Separation rate shock state')
    m_shock     $\hat{m}$       (long_name='Matching efficiency shock state')
;

varexo
    eps_a       $\varepsilon_A$      (long_name='Productivity innovation')
    eps_mu      $\varepsilon_\mu$    (long_name='Markup innovation')
    eps_q       $\varepsilon_q$      (long_name='Oil price innovation')
    eps_g       $\varepsilon_g$      (long_name='Demand innovation')
    eps_e       $\varepsilon_e$      (long_name='Monetary policy innovation')
    eps_chi     $\varepsilon_\chi$   (long_name='Labor participation innovation')
    eps_s       $\varepsilon_s$      (long_name='Separation rate innovation')
    eps_m       $\varepsilon_m$      (long_name='Matching efficiency innovation')
;

// -------------------------------------------------------------------------
// Parameters
// -------------------------------------------------------------------------

parameters
    // Structural parameters (Table A)
    sigma       $\sigma$        (long_name='Inverse IES')
    phi_pi      $\phi_\pi$      (long_name='Taylor rule coefficient on inflation')
    eta         $\eta$          (long_name='Matching function elasticity')
    u_bar       $\bar{u}$       (long_name='Steady-state unemployment rate')
    s_bar       $\bar{s}$       (long_name='Separation rate')
    alpha       $\alpha$        (long_name='Labor share in production')
    omega       $\omega$        (long_name='Inverse Frisch elasticity (GHH)')
    lambda_w    $\lambda$       (long_name='Wage rigidity parameter')
    beta_disc   $\beta$         (long_name='Discount factor')
    delta_w     $\delta$        (long_name='Inflation expectations weight in wage norm')

    // Phillips curve structural parameter
    phi_pc      $\Phi$          (long_name='Rotemberg slope: (epsilon-1)/varsigma')

    // Regime switch threshold
    theta_star  $\hat{\theta}^*$ (long_name='Tightness threshold for regime switch')

    // Composite steady-state ratios (derived from Table A)
    z_u         $z_u$           (long_name='(s_bar - u_bar) / s_bar')
    coeff_1s    $c_{1s}$        (long_name='(1-s_bar)/(1-u_bar)')
    coeff_su    $c_{su}$        (long_name='(s_bar-u_bar)/(1-u_bar)')
    coeff_u     $c_u$           (long_name='u_bar/(1-u_bar)')

    // Shock persistence
    rho_a       $\rho_A$        (long_name='Productivity shock persistence')
    rho_mu      $\rho_\mu$      (long_name='Markup shock persistence')
    rho_q       $\rho_q$        (long_name='Oil price shock persistence')
    rho_g       $\rho_g$        (long_name='Demand shock persistence')
    rho_e       $\rho_e$        (long_name='Monetary policy shock persistence')
    rho_chi     $\rho_\chi$     (long_name='Participation shock persistence')
    rho_s       $\rho_s$        (long_name='Separation rate shock persistence')
    rho_m       $\rho_m$        (long_name='Matching efficiency shock persistence')
;

// -------------------------------------------------------------------------
// Calibration
// -------------------------------------------------------------------------

// Structural parameters (Table A of BE 2025)
sigma       = 0.5;
phi_pi      = 1.5;
eta         = 0.4;
u_bar       = 0.04;
s_bar       = 0.0723;
alpha       = 0.9;
omega       = 1.0;
lambda_w    = 0.5;
beta_disc   = 0.99;
delta_w     = 1.0;

// Phillips curve slope: (epsilon - 1) / varsigma
// Calibrated to approximately match the tight-regime reduced-form slope
// kappa_tight = 0.0736 when mapped through the labor market block.
// With epsilon ~ 10, varsigma ~ 225: phi_pc = 9/225 = 0.04
phi_pc      = 0.04;

// Regime switch threshold: theta_star > 0 means the steady state has the
// wage norm slightly above the flexible wage (c_w > 0 in the paper).
// This provides a buffer zone for OccBin convergence, analogous to
// y_star = 0.01 in the simplified model. Mapped from the simplified
// model's y_star via the labor market block (approximate).
theta_star  = 0.01;

// Derived composite ratios
z_u         = (s_bar - u_bar) / s_bar;          // 0.4468
coeff_1s    = (1 - s_bar) / (1 - u_bar);        // 0.9664
coeff_su    = (s_bar - u_bar) / (1 - u_bar);    // 0.03365
coeff_u     = u_bar / (1 - u_bar);              // 0.04167

// Shock persistence (tau = 0.8 from paper's Markov structure)
rho_a       = 0.8;
rho_mu      = 0.8;
rho_q       = 0.8;
rho_g       = 0.8;
rho_e       = 0.5;      // Monetary policy shocks less persistent
rho_chi     = 0.8;
rho_s       = 0.8;
rho_m       = 0.8;

// -------------------------------------------------------------------------
// Model equations
// -------------------------------------------------------------------------

model;

    // =================================================================
    // BLOCK 1: PHILLIPS CURVE / AGGREGATE SUPPLY (eq. E.22)
    // =================================================================
    // pi_t = phi_pc * (mu_hat + alpha * w_new_hat - A_hat + (1-alpha)*q_hat)
    //        + beta * E_t pi_{t+1}
    //
    // This is the Rotemberg pricing FOC. The piecewise behavior arises
    // endogenously through w_new (which switches between w_ex and w_flex).
    // No separate bind/relax needed on this equation.

    [name='Phillips curve (Rotemberg)']
    pi = phi_pc * (mu_shock + alpha * w_new - a_shock + (1-alpha)*q_shock)
         + beta_disc * pi(+1);

    // =================================================================
    // BLOCK 2: WAGE SETTING
    // =================================================================

    // --- Flexible wage (eq. E.23, simplified: gamma^c, gamma^b omitted) ---
    // w_flex = eta * theta - m_shock
    [name='Flexible wage']
    w_flex = eta * theta - m_shock;

    // --- New hire wage (eq. 43, piecewise via OccBin) ---
    // Reference (slack) regime: w_new = w_ex (wage norm pins new hire wage)
    // Alternative (tight) regime: w_new = w_flex (market-clearing wage)
    //
    // With theta_star > 0, the kink is not at steady state. At the kink:
    //   w_flex(theta_star) = eta * theta_star
    //   w_new must be continuous: w_ex = w_flex at theta = theta_star
    // The tight-regime equation includes a continuity constant:
    //   w_new = w_flex - eta * theta_star + w_ex_at_kink
    // Since w_ex_at_kink ≈ eta * theta_star in the neighborhood of the kink
    // (from the slack regime where w_new = w_ex and the static relationship),
    // the constant simplifies. For first-order accuracy, we use:
    //   Slack: w_new = w_ex
    //   Tight: w_new = w_flex
    // and accept the small discontinuity at the threshold (order theta_star^2).

    [name='New hire wage', relax='tight_labor']
    w_new = w_ex;

    [name='New hire wage', bind='tight_labor']
    w_new = w_flex;

    // --- Existing wage evolution (log-linearized eq. 39) ---
    // w_ex_t = lambda * (w_ex_{t-1} - pi_t + delta * E_t pi_{t+1})
    //          + (1-lambda) * w_flex_t
    //
    // This is the same in BOTH regimes. w_ex is the wage norm for
    // existing/attached workers, blending past wages (adjusted for
    // inflation) with the current flexible wage.

    [name='Existing wage evolution']
    w_ex = lambda_w * (w_ex(-1) - pi + delta_w * pi(+1))
           + (1 - lambda_w) * w_flex;

    // =================================================================
    // BLOCK 3: LABOR MARKET
    // =================================================================

    // --- Unemployment (eq. F.28, from matching function) ---
    // u_hat = s_hat - z_u * (m_hat + (1-eta) * theta_hat)
    // where z_u = (s_bar - u_bar) / s_bar
    [name='Unemployment (matching)']
    u_rate = s_shock - z_u * (m_shock + (1 - eta) * theta);

    // --- Employment-participation link (eq. F.27) ---
    // N_hat = F_hat - (u_bar/(1-u_bar)) * u_hat
    [name='Employment-participation link']
    n_emp = f_lf - coeff_u * u_rate;

    // --- Labor force participation (eq. F.26) ---
    // omega * F_hat + chi_hat = coeff_1s * w_ex + coeff_su * w_new
    //                           - coeff_u * u_hat
    //
    // This equates marginal disutility of labor supply (LHS) to the
    // expected wage conditional on participation (RHS). The expected
    // wage weights existing-job wages (w_ex) and new-hire wages (w_new)
    // by their respective probabilities.
    [name='Labor force participation']
    omega * f_lf + chi_shock = coeff_1s * w_ex + coeff_su * w_new
                                - coeff_u * u_rate;

    // =================================================================
    // BLOCK 4: PRODUCTION
    // =================================================================

    // --- Production function (eq. F.31) ---
    // N_hat = (1/alpha) * (Y_hat - A_hat)
    [name='Production function']
    n_emp = (1/alpha) * (y - a_shock);

    // =================================================================
    // BLOCK 5: DEMAND SIDE
    // =================================================================

    // --- IS / Euler equation (eq. 47) ---
    // Y_hat - G_hat = E_t(Y_{t+1} - G_{t+1}) - sigma^{-1}(i_hat - E_t pi_{t+1})
    // Natural rate r^epsilon absorbed into demand shock g.
    [name='IS curve']
    y - g_shock = y(+1) - g_shock(+1) - (1/sigma) * (ii - pi(+1));

    // =================================================================
    // BLOCK 6: MONETARY POLICY
    // =================================================================

    // --- Taylor rule (eq. 49) ---
    // i_hat = phi_pi * pi_hat + e_hat
    [name='Taylor rule']
    ii = phi_pi * pi + e_shock;

    // =================================================================
    // BLOCK 7: SHOCK PROCESSES (AR(1))
    // =================================================================

    [name='Productivity shock']
    a_shock = rho_a * a_shock(-1) + eps_a;

    [name='Markup shock']
    mu_shock = rho_mu * mu_shock(-1) + eps_mu;

    [name='Oil price shock']
    q_shock = rho_q * q_shock(-1) + eps_q;

    [name='Demand shock']
    g_shock = rho_g * g_shock(-1) + eps_g;

    [name='Monetary policy shock']
    e_shock = rho_e * e_shock(-1) + eps_e;

    [name='Participation shock']
    chi_shock = rho_chi * chi_shock(-1) + eps_chi;

    [name='Separation rate shock']
    s_shock = rho_s * s_shock(-1) + eps_s;

    [name='Matching efficiency shock']
    m_shock = rho_m * m_shock(-1) + eps_m;

end;

// -------------------------------------------------------------------------
// OccBin constraint: regime switch at the wage kink
// -------------------------------------------------------------------------
// When the labor market is tight (theta > theta_star), the flexible wage
// exceeds the existing wage norm, so new hires receive the market-clearing
// wage. When slack (theta <= theta_star), new hires receive the wage norm.
//
// theta_star > 0 provides a buffer zone for OccBin convergence and
// reflects the paper's c_w > 0 calibration (wage norm slightly above
// the flexible wage at steady state).

occbin_constraints;
    name 'tight_labor';
    bind theta > theta_star;
    relax theta <= theta_star;
end;

// -------------------------------------------------------------------------
// Steady state (all zeros - model is in log-deviations)
// -------------------------------------------------------------------------

steady_state_model;
    pi       = 0;
    y        = 0;
    ii       = 0;
    theta    = 0;
    w_new    = 0;
    w_ex     = 0;
    w_flex   = 0;
    n_emp    = 0;
    f_lf     = 0;
    u_rate   = 0;
    a_shock  = 0;
    mu_shock = 0;
    q_shock  = 0;
    g_shock  = 0;
    e_shock  = 0;
    chi_shock = 0;
    s_shock  = 0;
    m_shock  = 0;
end;

// -------------------------------------------------------------------------
// Check steady state and Blanchard-Kahn conditions
// -------------------------------------------------------------------------

steady;
check;

// -------------------------------------------------------------------------
// OccBin deterministic scenarios using occbin_solver
// -------------------------------------------------------------------------
// Run non-binding scenarios first to avoid OccBin state contamination
// (persistent variables inside occbin.solver cache decision rules).

// --- Scenario 1: Supply shock (markup, no regime switch expected) ---
shocks(surprise, overwrite);
    var eps_mu;
    periods 1;
    values 0.01;
end;

occbin_setup(simul_periods=40, simul_check_ahead_periods=40, simul_maxit=100);
occbin_solver;

verbatim;
    results_supply.piecewise = oo_.occbin.simul.piecewise;
    results_supply.linear    = oo_.occbin.simul.linear;
    fprintf('\n=== Scenario 1 (markup shock) completed ===\n');
end;

// --- Scenario 2: Negative demand shock (no regime switch expected) ---
shocks(surprise, overwrite);
    var eps_g;
    periods 1;
    values -0.05;
end;

occbin_setup(simul_periods=40, simul_check_ahead_periods=40, simul_maxit=100);
occbin_solver;

verbatim;
    results_neg_demand.piecewise = oo_.occbin.simul.piecewise;
    results_neg_demand.linear    = oo_.occbin.simul.linear;
    fprintf('\n=== Scenario 2 (negative demand) completed ===\n');
end;

// --- Scenario 3: Matching efficiency shock (labor market specific) ---
shocks(surprise, overwrite);
    var eps_m;
    periods 1;
    values -0.05;
end;

occbin_setup(simul_periods=40, simul_check_ahead_periods=40, simul_maxit=100);
occbin_solver;

verbatim;
    results_matching.piecewise = oo_.occbin.simul.piecewise;
    results_matching.linear    = oo_.occbin.simul.linear;
    fprintf('\n=== Scenario 3 (matching efficiency shock) completed ===\n');
end;

// --- Scenario 4: Large positive demand shock (triggers tight regime) ---
shocks(surprise, overwrite);
    var eps_g;
    periods 1;
    values 0.05;
end;

occbin_setup(simul_periods=40, simul_check_ahead_periods=40, simul_maxit=100);
occbin_solver;

verbatim;
    results_demand.piecewise = oo_.occbin.simul.piecewise;
    results_demand.linear    = oo_.occbin.simul.linear;
    fprintf('\n=== Scenario 4 (positive demand shock) completed ===\n');
    fprintf('y(1) = %.6f, pi(1) = %.6f, theta(1) = %.6f\n', ...
            results_demand.piecewise(1, strmatch('y', M_.endo_names, 'exact')), ...
            results_demand.piecewise(1, strmatch('pi', M_.endo_names, 'exact')), ...
            results_demand.piecewise(1, strmatch('theta', M_.endo_names, 'exact')));
end;

// --- Scenario 5: Oil price shock (tests cost-push channel) ---
shocks(surprise, overwrite);
    var eps_q;
    periods 1;
    values 0.10;
end;

occbin_setup(simul_periods=40, simul_check_ahead_periods=40, simul_maxit=100);
occbin_solver;

verbatim;
    results_oil.piecewise = oo_.occbin.simul.piecewise;
    results_oil.linear    = oo_.occbin.simul.linear;
    fprintf('\n=== Scenario 5 (oil price shock) completed ===\n');
end;

// --- Scenario 6: Separation rate shock (labor market specific) ---
// Reduced shock size to avoid OccBin convergence issues near the
// regime boundary. The separation shock raises unemployment but also
// interacts with the wage dynamics in ways that can cause oscillation.
shocks(surprise, overwrite);
    var eps_s;
    periods 1;
    values 0.01;
end;

occbin_setup(simul_periods=40, simul_check_ahead_periods=40, simul_maxit=100);
occbin_solver;

verbatim;
    results_separation.piecewise = oo_.occbin.simul.piecewise;
    results_separation.linear    = oo_.occbin.simul.linear;
    fprintf('\n=== Scenario 6 (separation rate shock) completed ===\n');
end;
