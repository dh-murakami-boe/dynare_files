// =========================================================================
// Benigno and Eggertsson (2025): Full Structural Model — Twist Extension
// with Search-and-Matching Labor Market and Inverted Nonlinear Phillips Curve
//
// Implementation using Dynare 6.5 OccBin toolkit
// Author:  David Murakami
// Date:    2026-03-02
// Quarterly frequency
//
// Reference: Benigno, P. and Eggertsson, G. (2025)
// "It's Baaack: The Surge in Inflation"
//
// TWIST EXTENSION — inverted nonlinearity relative to be_structural.mod:
//
//   ORIGINAL (be_structural.mod):
//     Slack (normal times, theta <= theta_star): w_new = w_ex   [wage norm binds]
//     Tight (boom, theta > theta_star):          w_new = w_flex  [wage norm slack]
//     => Phillips curve is STEEP in booms, FLAT in recessions.
//
//   TWIST (this file):
//     Normal (theta >= theta_low):               w_new = w_flex  [wage norm slack]
//     Deep recession (theta < theta_low):        w_new = w_ex    [wage norm binds]
//     => Phillips curve is STEEP in normal times, FLAT in deep recessions.
//
// The twist embeds a "wage norm binding" constraint: in sufficiently deep
// recessions (log-deviation of tightness falls below theta_low < 0), the
// wage norm constrains new hire wages from below, decoupling inflation from
// further deterioration of labor market conditions. This inverts the
// standard DNWR story and produces a Phillips curve that flattens only at
// the lower tail — a distinct empirical prediction to be tested against data.
//
// The regime switch is on labor market tightness (theta vs. theta_low) rather
// than on the wage comparison directly. All other structural equations are
// identical to be_structural.mod.
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

    // Regime switch threshold (twist: negative, marks deep recession boundary)
    theta_low   $\hat{\theta}_{low}$ (long_name='Tightness threshold for wage norm binding (< 0)')

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
// Calibrated to approximately match the normal-regime reduced-form slope.
// Same value as be_structural.mod for comparability.
phi_pc      = 0.04;

// Twist threshold: theta_low < 0 defines the deep-recession region where
// the wage norm binds. Set to -0.05 (a 5% log-deviation below steady-state
// tightness). In normal times (theta >= theta_low) wages are flexible;
// only in sufficiently severe downturns does the wage norm constrain new
// hire wages from below, producing a flat Phillips curve at the lower tail.
theta_low   = -0.05;

// Derived composite ratios (identical to be_structural.mod)
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
    // endogenously through w_new (which switches between w_flex and w_ex).
    // In the twist, w_new = w_flex in normal times (wage norm slack) and
    // w_new = w_ex in deep recessions (wage norm binding), so inflation
    // is less responsive to further deterioration once theta < theta_low.
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

    // --- New hire wage (eq. 43, piecewise via OccBin) --- TWIST VERSION ---
    // In the twist, the wage norm binding is the UNUSUAL state (deep recession).
    // Reference (normal) regime: w_new = w_flex (market-clearing wage prevails)
    // Binding (deep recession) regime: w_new = w_ex (wage norm constrains wages)
    //
    // Economic logic: In normal times, firms and workers bargain freely so new
    // hire wages equal the flexible wage. Only when the labor market collapses
    // far enough (theta < theta_low) does the wage norm bind from below —
    // workers resist nominal wage cuts below their existing wage norm even
    // when the flexible wage would call for a lower wage. This flattens the
    // PC at the lower tail, insulating inflation from deep-recession dynamics.

    [name='New hire wage', relax='wage_norm_binding']
    w_new = w_flex;

    [name='New hire wage', bind='wage_norm_binding']
    w_new = w_ex;

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
// OccBin constraint: regime switch at the wage norm binding threshold
// -------------------------------------------------------------------------
// When the labor market is sufficiently depressed (theta < theta_low < 0),
// the wage norm binds: new hire wages are constrained by the existing wage
// norm (w_new = w_ex). In normal times (theta >= theta_low), the wage norm
// is slack and new hires receive the market-clearing flexible wage.
//
// theta_low = -0.05 places the kink 5 log-deviation points below steady
// state, ensuring the model is in the normal (relax) regime in steady state
// and only switches to the wage-norm-binding (bind) regime during severe
// downturns. This mirrors the role of theta_star in be_structural.mod but
// for the opposite tail of the tightness distribution.

occbin_constraints;
    name 'wage_norm_binding';
    bind theta < theta_low;
    relax theta >= theta_low;
end;

// -------------------------------------------------------------------------
// Steady state (all zeros - model is in log-deviations)
// -------------------------------------------------------------------------

steady_state_model;
    pi        = 0;
    y         = 0;
    ii        = 0;
    theta     = 0;
    w_new     = 0;
    w_ex      = 0;
    w_flex    = 0;
    n_emp     = 0;
    f_lf      = 0;
    u_rate    = 0;
    a_shock   = 0;
    mu_shock  = 0;
    q_shock   = 0;
    g_shock   = 0;
    e_shock   = 0;
    chi_shock = 0;
    s_shock   = 0;
    m_shock   = 0;
end;

// -------------------------------------------------------------------------
// Check steady state and Blanchard-Kahn conditions
// -------------------------------------------------------------------------

steady;
check;

// -------------------------------------------------------------------------
// OccBin deterministic scenarios using occbin_solver
// -------------------------------------------------------------------------
// Non-binding scenarios are run FIRST to avoid OccBin state contamination.
// In the twist, the non-binding (normal) regime is the default, so small
// shocks and positive demand/cost-push shocks do not trigger regime switch.
// The binding (wage norm binding) regime is only triggered by shocks large
// enough to push theta below theta_low = -0.05.
//
// Approximate first-period tightness responses (linear regime, rho_g=0.8):
//   eps_g = -0.02 => theta(1) ~ -0.045  (non-binding, just above theta_low)
//   eps_g = +0.05 => theta(1) >> 0      (non-binding, booming labor market)
//   eps_mu = +0.01 => theta(1) ~ small negative (non-binding)
//   eps_q = +0.10 => theta(1) ~ moderate negative (non-binding)
//   eps_g = -0.05 => theta(1) ~ -0.112  (binding, well below theta_low)
//   eps_g = -0.05 + eps_mu = +0.01 => binding with supply-side interaction
//
// Non-binding scenarios first (OccBin ordering rule):

// --- Scenario 1: Small negative demand shock (non-binding expected) ---
// theta(1) ~ -0.045 > theta_low = -0.05: wage norm slack, normal PC slope.
shocks(surprise, overwrite);
    var eps_g;
    periods 1;
    values -0.02;
end;

occbin_setup(simul_periods=40, simul_check_ahead_periods=40, simul_maxit=100);
occbin_solver;

verbatim;
    results_small_neg.piecewise = oo_.occbin.simul.piecewise;
    results_small_neg.linear    = oo_.occbin.simul.linear;
    idx_y     = strmatch('y',     M_.endo_names, 'exact');
    idx_pi    = strmatch('pi',    M_.endo_names, 'exact');
    idx_theta = strmatch('theta', M_.endo_names, 'exact');
    fprintf('\n=== Scenario 1 (small negative demand, eps_g=-0.02) ===\n');
    fprintf('  y(1)     = %.6f\n', results_small_neg.piecewise(1, idx_y));
    fprintf('  pi(1)    = %.6f\n', results_small_neg.piecewise(1, idx_pi));
    fprintf('  theta(1) = %.6f  [theta_low = -0.05]\n', results_small_neg.piecewise(1, idx_theta));
    fprintf('  Regime: wage norm SLACK (normal times)\n');
end;

// --- Scenario 2: Positive demand shock (non-binding) ---
// Large positive demand shock: theta >> 0, far from binding region.
// Normal PC slope prevails throughout. Validates the non-binding path.
shocks(surprise, overwrite);
    var eps_g;
    periods 1;
    values 0.05;
end;

occbin_setup(simul_periods=40, simul_check_ahead_periods=40, simul_maxit=100);
occbin_solver;

verbatim;
    results_pos_demand.piecewise = oo_.occbin.simul.piecewise;
    results_pos_demand.linear    = oo_.occbin.simul.linear;
    idx_y     = strmatch('y',     M_.endo_names, 'exact');
    idx_pi    = strmatch('pi',    M_.endo_names, 'exact');
    idx_theta = strmatch('theta', M_.endo_names, 'exact');
    fprintf('\n=== Scenario 2 (positive demand, eps_g=+0.05) ===\n');
    fprintf('  y(1)     = %.6f\n', results_pos_demand.piecewise(1, idx_y));
    fprintf('  pi(1)    = %.6f\n', results_pos_demand.piecewise(1, idx_pi));
    fprintf('  theta(1) = %.6f  [theta_low = -0.05]\n', results_pos_demand.piecewise(1, idx_theta));
    fprintf('  Regime: wage norm SLACK (labor market booming)\n');
end;

// --- Scenario 3: Markup shock (non-binding) ---
// Cost-push shock raises marginal costs and inflation; labor market
// tightness falls moderately but remains above theta_low. Tests the
// supply-side channel under the normal PC regime.
shocks(surprise, overwrite);
    var eps_mu;
    periods 1;
    values 0.01;
end;

occbin_setup(simul_periods=40, simul_check_ahead_periods=40, simul_maxit=100);
occbin_solver;

verbatim;
    results_markup.piecewise = oo_.occbin.simul.piecewise;
    results_markup.linear    = oo_.occbin.simul.linear;
    idx_y     = strmatch('y',     M_.endo_names, 'exact');
    idx_pi    = strmatch('pi',    M_.endo_names, 'exact');
    idx_theta = strmatch('theta', M_.endo_names, 'exact');
    fprintf('\n=== Scenario 3 (markup shock, eps_mu=+0.01) ===\n');
    fprintf('  y(1)     = %.6f\n', results_markup.piecewise(1, idx_y));
    fprintf('  pi(1)    = %.6f\n', results_markup.piecewise(1, idx_pi));
    fprintf('  theta(1) = %.6f  [theta_low = -0.05]\n', results_markup.piecewise(1, idx_theta));
    fprintf('  Regime: wage norm SLACK\n');
end;

// --- Scenario 4: Oil price shock (non-binding) ---
// Large oil/intermediate input shock raises marginal costs via (1-alpha)*q.
// Demand contracts but tightness stays above theta_low. Tests the energy
// cost channel under normal regime.
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
    idx_y     = strmatch('y',     M_.endo_names, 'exact');
    idx_pi    = strmatch('pi',    M_.endo_names, 'exact');
    idx_theta = strmatch('theta', M_.endo_names, 'exact');
    fprintf('\n=== Scenario 4 (oil price shock, eps_q=+0.10) ===\n');
    fprintf('  y(1)     = %.6f\n', results_oil.piecewise(1, idx_y));
    fprintf('  pi(1)    = %.6f\n', results_oil.piecewise(1, idx_pi));
    fprintf('  theta(1) = %.6f  [theta_low = -0.05]\n', results_oil.piecewise(1, idx_theta));
    fprintf('  Regime: wage norm SLACK\n');
end;

// --- Scenario 5: Large recession (binding — wage norm engages) ---
// Large negative demand shock pushes theta well below theta_low = -0.05.
// The wage norm binds: w_new = w_ex, decoupling inflation from further
// labor market deterioration and flattening the effective PC.
// NOTE: run AFTER all non-binding scenarios (OccBin ordering rule).
shocks(surprise, overwrite);
    var eps_g;
    periods 1;
    values -0.05;
end;

occbin_setup(simul_periods=40, simul_check_ahead_periods=40, simul_maxit=100);
occbin_solver;

verbatim;
    results_recession.piecewise = oo_.occbin.simul.piecewise;
    results_recession.linear    = oo_.occbin.simul.linear;
    idx_y     = strmatch('y',     M_.endo_names, 'exact');
    idx_pi    = strmatch('pi',    M_.endo_names, 'exact');
    idx_theta = strmatch('theta', M_.endo_names, 'exact');
    idx_wnew  = strmatch('w_new', M_.endo_names, 'exact');
    idx_wex   = strmatch('w_ex',  M_.endo_names, 'exact');
    fprintf('\n=== Scenario 5 (large recession, eps_g=-0.05) ===\n');
    fprintf('  y(1)     = %.6f\n', results_recession.piecewise(1, idx_y));
    fprintf('  pi(1)    = %.6f\n', results_recession.piecewise(1, idx_pi));
    fprintf('  theta(1) = %.6f  [theta_low = -0.05]\n', results_recession.piecewise(1, idx_theta));
    fprintf('  w_new(1) = %.6f,  w_ex(1) = %.6f\n', ...
            results_recession.piecewise(1, idx_wnew), ...
            results_recession.piecewise(1, idx_wex));
    if results_recession.piecewise(1, idx_theta) < -0.05
        fprintf('  Regime: wage norm BINDING (deep recession)\n');
    else
        fprintf('  Regime: wage norm SLACK (check shock size)\n');
    end;
end;

// --- Scenario 6: Recession with markup shock (binding + supply interaction) ---
// Large recession combined with a markup shock tests the interaction of
// the wage norm binding constraint with cost-push pressures. The wage norm
// limits the pass-through of the recession into inflation, but the markup
// shock adds a direct cost-push component through mu_shock in the PC.
shocks(surprise, overwrite);
    var eps_g;
    periods 1;
    values -0.05;
    var eps_mu;
    periods 1;
    values 0.01;
end;

occbin_setup(simul_periods=40, simul_check_ahead_periods=40, simul_maxit=100);
occbin_solver;

verbatim;
    results_rec_markup.piecewise = oo_.occbin.simul.piecewise;
    results_rec_markup.linear    = oo_.occbin.simul.linear;
    idx_y     = strmatch('y',     M_.endo_names, 'exact');
    idx_pi    = strmatch('pi',    M_.endo_names, 'exact');
    idx_theta = strmatch('theta', M_.endo_names, 'exact');
    idx_wnew  = strmatch('w_new', M_.endo_names, 'exact');
    idx_wex   = strmatch('w_ex',  M_.endo_names, 'exact');
    fprintf('\n=== Scenario 6 (recession + markup, eps_g=-0.05, eps_mu=+0.01) ===\n');
    fprintf('  y(1)     = %.6f\n', results_rec_markup.piecewise(1, idx_y));
    fprintf('  pi(1)    = %.6f\n', results_rec_markup.piecewise(1, idx_pi));
    fprintf('  theta(1) = %.6f  [theta_low = -0.05]\n', results_rec_markup.piecewise(1, idx_theta));
    fprintf('  w_new(1) = %.6f,  w_ex(1) = %.6f\n', ...
            results_rec_markup.piecewise(1, idx_wnew), ...
            results_rec_markup.piecewise(1, idx_wex));
    if results_rec_markup.piecewise(1, idx_theta) < -0.05
        fprintf('  Regime: wage norm BINDING (deep recession + cost push)\n');
    else
        fprintf('  Regime: wage norm SLACK (check shock size)\n');
    end;
    fprintf('\n=== All twist scenarios completed ===\n');
end;
