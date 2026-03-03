%% run_be_structural_twist.m
% =========================================================================
% Driver script: Structural Twist on Benigno & Eggertsson (2025)
% Full structural model with search-and-matching labor market, where the
% nonlinearity is inverted relative to the baseline:
%   Normal times (theta >= theta_low): flexible wage rules, w_new = w_flex
%   Deep recession (theta < theta_low): wage norm binds, w_new = w_ex
%
% This produces "missing disinflation" in severe recessions rather than
% in the slack/normal times of the original Inverse-L specification.
%
% This script:
%   1. Runs the Dynare model be_structural_twist.mod (6 OccBin scenarios)
%   2. Figure 1: Demand shock asymmetry (3x2 subplots)
%   3. Figure 2: Supply shocks in normal times (2x3 subplots)
%   4. Figure 3: Static twist AS curve vs. original Inverse-L
%   5. Figure 4: Missing disinflation detail (large recession focus)
%   6. Summary diagnostics printed to console
%
% Scenarios (in order of execution in .mod file):
%   results_small_neg          — Scen 1: small negative demand (eps_g = -0.02)
%   results_pos_demand                — Scen 2: positive demand     (eps_g = +0.05)
%   results_markup             — Scen 3: markup shock        (eps_mu = +0.01)
%   results_oil                — Scen 4: oil price shock     (eps_q = +0.10)
%   results_recession          — Scen 5: large recession     (eps_g = -0.05)
%   results_rec_markup   — Scen 6: recession + markup  (eps_g=-0.05, eps_mu=+0.01)
%
% Requirements: MATLAB R2025b, Dynare 6.5
%
% Reference: Benigno, P. and Eggertsson, G. (2025)
%   "It's Baaack: The Surge in Inflation"
%
% Note on variable naming: MATLAB interprets 'theta' as a toolbox function.
%   Use th_val, th_grid, etc. for workspace variables that hold theta values.
%   The model variable 'theta' is referenced only via idx.theta indexing.
% =========================================================================

clear; close all; clc;

%% 1. Run Dynare model
% =========================================================================
% After dynare completes the following Dynare workspace variables are live:
%   M_      — model metadata (variable names, parameter names and values)
%   oo_     — output structure (OccBin results, steady state, etc.)
%   options_ — Dynare options
%
% The six result structs (.piecewise, .linear) are populated inside
% verbatim blocks of be_structural_twist.mod.

dynare be_structural_twist noclearall;

global M_ oo_ options_;

%% 2. Extract variable indices
% =========================================================================
% OccBin stores results in oo_.occbin.simul.piecewise (T x nvar matrix).
% Column ordering follows the var declaration order in the .mod file.
% Endogenous variables (10 core + 8 shock states = 18 total):
%   pi, y, ii, theta, w_new, w_ex, w_flex, n_emp, f_lf, u_rate,
%   a_shock, mu_shock, q_shock, g_shock, e_shock, chi_shock, s_shock, m_shock

var_names = M_.endo_names;
idx = struct();
idx.pi     = strmatch('pi',       var_names, 'exact');
idx.y      = strmatch('y',        var_names, 'exact');
idx.ii     = strmatch('ii',       var_names, 'exact');
idx.theta  = strmatch('theta',    var_names, 'exact');
idx.w_new  = strmatch('w_new',    var_names, 'exact');
idx.w_ex   = strmatch('w_ex',     var_names, 'exact');
idx.w_flex = strmatch('w_flex',   var_names, 'exact');
idx.n_emp  = strmatch('n_emp',    var_names, 'exact');
idx.f_lf   = strmatch('f_lf',     var_names, 'exact');
idx.u_rate = strmatch('u_rate',   var_names, 'exact');

% Simulation horizon
T_simul  = 40;
quarters = (1:T_simul)';

%% 3. Retrieve calibrated parameters
% =========================================================================
p_names = M_.param_names;

phi_pc_val  = M_.params(strmatch('phi_pc',      p_names, 'exact'));
alpha_val   = M_.params(strmatch('alpha',        p_names, 'exact'));
eta_val     = M_.params(strmatch('eta',          p_names, 'exact'));
omega_val   = M_.params(strmatch('omega',        p_names, 'exact'));
lambda_val  = M_.params(strmatch('lambda_w',     p_names, 'exact'));
beta_val    = M_.params(strmatch('beta_disc',    p_names, 'exact'));
sigma_val   = M_.params(strmatch('sigma',        p_names, 'exact'));
phipi_val   = M_.params(strmatch('phi_pi',       p_names, 'exact'));
z_u_val     = M_.params(strmatch('z_u',          p_names, 'exact'));
c1s_val     = M_.params(strmatch('coeff_1s',     p_names, 'exact'));
csu_val     = M_.params(strmatch('coeff_su',     p_names, 'exact'));
cu_val      = M_.params(strmatch('coeff_u',      p_names, 'exact'));
u_bar_val   = M_.params(strmatch('u_bar',        p_names, 'exact'));
th_low_val  = M_.params(strmatch('theta_low',    p_names, 'exact'));  % twist threshold

%% 4. Extract scenario IRFs
% =========================================================================
% Each struct has .piecewise (T x nvar) and .linear (T x nvar) matrices.
% Column indices follow the var declaration order above.

% Scenario 1: small negative demand (non-binding — above theta_low)
y_sn   = results_small_neg.piecewise(:, idx.y);
pi_sn  = results_small_neg.piecewise(:, idx.pi);
th_sn  = results_small_neg.piecewise(:, idx.theta);
wn_sn  = results_small_neg.piecewise(:, idx.w_new);
wx_sn  = results_small_neg.piecewise(:, idx.w_ex);
u_sn   = results_small_neg.piecewise(:, idx.u_rate);

% Scenario 2: positive demand (non-binding)
y_pos  = results_pos_demand.piecewise(:, idx.y);
pi_pos = results_pos_demand.piecewise(:, idx.pi);
th_pos = results_pos_demand.piecewise(:, idx.theta);
wn_pos = results_pos_demand.piecewise(:, idx.w_new);
wx_pos = results_pos_demand.piecewise(:, idx.w_ex);
u_pos  = results_pos_demand.piecewise(:, idx.u_rate);

% Scenario 3: markup shock (non-binding)
y_mu   = results_markup.piecewise(:, idx.y);
pi_mu  = results_markup.piecewise(:, idx.pi);
th_mu  = results_markup.piecewise(:, idx.theta);
wn_mu  = results_markup.piecewise(:, idx.w_new);
u_mu   = results_markup.piecewise(:, idx.u_rate);

% Scenario 4: oil price shock (non-binding)
y_oil  = results_oil.piecewise(:, idx.y);
pi_oil = results_oil.piecewise(:, idx.pi);
th_oil = results_oil.piecewise(:, idx.theta);
wn_oil = results_oil.piecewise(:, idx.w_new);
u_oil  = results_oil.piecewise(:, idx.u_rate);

% Scenario 5: large recession (piecewise = wage norm binding; linear = no binding)
y_rec      = results_recession.piecewise(:, idx.y);
pi_rec     = results_recession.piecewise(:, idx.pi);
th_rec     = results_recession.piecewise(:, idx.theta);
wn_rec     = results_recession.piecewise(:, idx.w_new);
wx_rec     = results_recession.piecewise(:, idx.w_ex);
u_rec      = results_recession.piecewise(:, idx.u_rate);
y_rec_lin  = results_recession.linear(:, idx.y);
pi_rec_lin = results_recession.linear(:, idx.pi);

% Scenario 6: large recession + markup (piecewise = wage norm binding)
y_rs   = results_rec_markup.piecewise(:, idx.y);
pi_rs  = results_rec_markup.piecewise(:, idx.pi);

%% 5. Figure 1: Demand Shock Asymmetry (3x2)
% =========================================================================
% Compares 3 scenarios:
%   - Positive demand (blue-red): non-binding, normal-slope PC
%   - Small negative demand (black): non-binding, normal-slope PC
%   - Large recession (blue): binding wage norm, flat PC; linear counterfactual (gray)
%
% Key insight: in the twist model, the asymmetry is recession-side.
% A positive or moderate negative shock produces proportional inflation/disinflation.
% Only a large enough negative shock (theta < theta_low) triggers the flat PC.

fig1 = figure('Name', 'Structural Twist: Demand Shock Asymmetry', ...
              'Position', [60 60 1150 820]);

% Color conventions
c_rec  = [0.15 0.35 0.75];   % blue: large recession (piecewise)
c_pos  = [0.85 0.15 0.15];   % red: positive demand
c_sn   = [0.15 0.15 0.15];   % black: small negative demand
c_lin  = [0.55 0.55 0.55];   % gray: linear counterfactual

% --- (1,1): Output gap ---
subplot(3,2,1);
plot(quarters, y_rec*100,     '-',  'Color', c_rec, 'LineWidth', 2.0);  hold on;
plot(quarters, y_pos*100,     '-',  'Color', c_pos, 'LineWidth', 2.0);
plot(quarters, y_sn*100,      '-',  'Color', c_sn,  'LineWidth', 2.0);
plot(quarters, y_rec_lin*100, '--', 'Color', c_lin, 'LineWidth', 1.5);
yline(0, 'k:', 'LineWidth', 0.8);
ylabel('Percent deviation');
xlabel('Quarters after shock');
title('Output Gap (y)');
legend('Large recession (piecewise)', ...
       'Positive demand', ...
       'Small negative demand', ...
       'Large recession (linear)', ...
       'Location', 'southeast', 'FontSize', 8);
grid on;

% --- (1,2): Inflation (annualized) ---
subplot(3,2,2);
plot(quarters, pi_rec*400,     '-',  'Color', c_rec, 'LineWidth', 2.0);  hold on;
plot(quarters, pi_pos*400,     '-',  'Color', c_pos, 'LineWidth', 2.0);
plot(quarters, pi_sn*400,      '-',  'Color', c_sn,  'LineWidth', 2.0);
plot(quarters, pi_rec_lin*400, '--', 'Color', c_lin, 'LineWidth', 1.5);
yline(0, 'k:', 'LineWidth', 0.8);
% Annotate missing disinflation gap at impact
gap_pp = (pi_rec_lin(1) - pi_rec(1)) * 400;
if abs(gap_pp) > 0.01
    text(3, (pi_rec(1) + 0.5*(pi_rec_lin(1)-pi_rec(1)))*400, ...
         sprintf('\\Deltapi \\approx %.2f pp\n(missing disinfl.)', gap_pp), ...
         'FontSize', 8, 'Color', c_rec, 'HorizontalAlignment', 'left');
end
ylabel('Percentage points (annualized)');
xlabel('Quarters after shock');
title('Inflation \pi (annualized = \pi \times 400)');
legend('Large recession (piecewise)', ...
       'Positive demand', ...
       'Small negative demand', ...
       'Large recession (linear)', ...
       'Location', 'best', 'FontSize', 8);
grid on;

% --- (2,1): Labor market tightness with theta_low threshold ---
subplot(3,2,3);
plot(quarters, th_rec*100,  '-',  'Color', c_rec, 'LineWidth', 2.0);  hold on;
plot(quarters, th_pos*100,  '-',  'Color', c_pos, 'LineWidth', 2.0);
plot(quarters, th_sn*100,   '-',  'Color', c_sn,  'LineWidth', 2.0);
% Mark the binding threshold theta_low
yline(th_low_val*100, 'b--', '\theta_{low}', 'LineWidth', 1.5, ...
      'LabelHorizontalAlignment', 'left', 'FontSize', 9);
yline(0, 'k:', 'LineWidth', 0.8);
ylabel('Percent deviation');
xlabel('Quarters after shock');
title('Labor Market Tightness (\theta)');
legend('Large recession', 'Positive demand', 'Small negative', ...
       'Location', 'southeast', 'FontSize', 8);
grid on;

% --- (2,2): Wages — w_new vs w_ex (shows binding for large recession) ---
% When wage norm binds: w_new = w_ex (they coincide). In normal times: w_new = w_flex > w_ex.
subplot(3,2,4);
plot(quarters, wn_rec*100, '-',  'Color', c_rec,           'LineWidth', 2.0);  hold on;
plot(quarters, wx_rec*100, '--', 'Color', c_rec,           'LineWidth', 1.8);
plot(quarters, wn_pos*100, '-',  'Color', c_pos,           'LineWidth', 2.0);
plot(quarters, wx_pos*100, '--', 'Color', c_pos,           'LineWidth', 1.8);
plot(quarters, wn_sn*100,  '-',  'Color', c_sn,            'LineWidth', 2.0);
yline(0, 'k:', 'LineWidth', 0.8);
ylabel('Percent deviation');
xlabel('Quarters after shock');
title('Wages: w^{new} (solid) vs w^{ex} (dashed)');
legend('w^{new} recession', 'w^{ex} recession', ...
       'w^{new} positive', 'w^{ex} positive', ...
       'w^{new} small neg.', ...
       'Location', 'best', 'FontSize', 8);
grid on;

% --- (3,1): Unemployment rate ---
subplot(3,2,5);
plot(quarters, u_rec*100, '-',  'Color', c_rec, 'LineWidth', 2.0);  hold on;
plot(quarters, u_pos*100, '-',  'Color', c_pos, 'LineWidth', 2.0);
plot(quarters, u_sn*100,  '-',  'Color', c_sn,  'LineWidth', 2.0);
yline(0, 'k:', 'LineWidth', 0.8);
ylabel('Percent deviation');
xlabel('Quarters after shock');
title('Unemployment Rate');
legend('Large recession', 'Positive demand', 'Small negative', ...
       'Location', 'best', 'FontSize', 8);
grid on;

% --- (3,2): Dynamic Phillips curve — (y, pi) scatter paths ---
% The kink is visible at theta ~ theta_low: the large recession path transitions
% from normal slope to flat as theta crosses theta_low.
subplot(3,2,6);

% Plot dynamic paths
plot(y_rec*100,     pi_rec*400,     '-.',  'Color', c_rec, 'LineWidth', 1.8, 'MarkerSize', 9); hold on;
plot(y_pos*100,     pi_pos*400,     '-.',  'Color', c_pos, 'LineWidth', 1.8, 'MarkerSize', 9);
plot(y_sn*100,      pi_sn*400,      '-.',  'Color', c_sn,  'LineWidth', 1.8, 'MarkerSize', 9);
plot(y_rec_lin*100, pi_rec_lin*400, ':',   'Color', c_lin, 'LineWidth', 1.5);
% Impact period markers
plot(y_rec(1)*100,  pi_rec(1)*400,  's', 'Color', c_rec, 'MarkerSize', 8, 'MarkerFaceColor', c_rec);
plot(y_pos(1)*100,  pi_pos(1)*400,  's', 'Color', c_pos, 'MarkerSize', 8, 'MarkerFaceColor', c_pos);
plot(y_sn(1)*100,   pi_sn(1)*400,   's', 'Color', c_sn,  'MarkerSize', 8, 'MarkerFaceColor', c_sn);
yline(0, 'k:', 'LineWidth', 0.5);
xlabel('Output Gap (%)');
ylabel('Inflation (annualized, pp)');
title('Dynamic Phillips Curve (\pi vs y paths)');
legend('Large recession (piecewise)', ...
       'Positive demand', 'Small negative', ...
       'Large recession (linear)', ...
       'Location', 'best', 'FontSize', 8);
grid on;

sgtitle('Structural Twist: Demand Shock Asymmetry (BE 2025)', ...
        'FontSize', 13, 'FontWeight', 'bold');

exportgraphics(fig1, '/Users/hiro/Desktop/nonlinear_labour/be_model/fig_structural_twist_demand_asymmetry.pdf', ...
               'Resolution', 300);
fprintf('\nFigure 1 saved: fig_structural_twist_demand_asymmetry.pdf\n');

%% 6. Figure 2: Supply Shocks in Normal Times (2x3)
% =========================================================================
% Both scenarios are non-binding (theta stays above theta_low).
% The wage norm is not active: w_new = w_flex in both cases.
% Compares markup shock (eps_mu = +0.01) vs oil price shock (eps_q = +0.10).

fig2 = figure('Name', 'Structural Twist: Supply Shocks', ...
              'Position', [60 60 1150 680]);

c_mu  = [0.15 0.35 0.75];   % blue: markup
c_oil = [0.85 0.45 0.05];   % orange: oil

% --- (1,1): Output ---
subplot(2,3,1);
plot(quarters, y_mu*100,  '-', 'Color', c_mu,  'LineWidth', 2.0);  hold on;
plot(quarters, y_oil*100, '-', 'Color', c_oil, 'LineWidth', 2.0);
yline(0, 'k:', 'LineWidth', 0.8);
ylabel('Percent deviation');
xlabel('Quarters');
title('Output Gap (y)');
legend('Markup (\mu)', 'Oil price (q)', 'Location', 'best', 'FontSize', 9);
grid on;

% --- (1,2): Inflation ---
subplot(2,3,2);
plot(quarters, pi_mu*400,  '-', 'Color', c_mu,  'LineWidth', 2.0);  hold on;
plot(quarters, pi_oil*400, '-', 'Color', c_oil, 'LineWidth', 2.0);
yline(0, 'k:', 'LineWidth', 0.8);
ylabel('Percentage points (annualized)');
xlabel('Quarters');
title('Inflation (annualized)');
legend('Markup (\mu)', 'Oil price (q)', 'Location', 'best', 'FontSize', 9);
grid on;

% --- (1,3): Tightness ---
subplot(2,3,3);
plot(quarters, th_mu*100,  '-', 'Color', c_mu,  'LineWidth', 2.0);  hold on;
plot(quarters, th_oil*100, '-', 'Color', c_oil, 'LineWidth', 2.0);
yline(th_low_val*100, 'k--', '\theta_{low}', 'LineWidth', 1.2, ...
      'LabelHorizontalAlignment', 'left', 'FontSize', 9);
yline(0, 'k:', 'LineWidth', 0.8);
ylabel('Percent deviation');
xlabel('Quarters');
title('Labor Market Tightness (\theta)');
legend('Markup (\mu)', 'Oil price (q)', 'Location', 'best', 'FontSize', 9);
grid on;

% --- (2,1): New hire wage ---
subplot(2,3,4);
plot(quarters, wn_mu*100,  '-', 'Color', c_mu,  'LineWidth', 2.0);  hold on;
plot(quarters, wn_oil*100, '-', 'Color', c_oil, 'LineWidth', 2.0);
yline(0, 'k:', 'LineWidth', 0.8);
ylabel('Percent deviation');
xlabel('Quarters');
title('New Hire Wage (w^{new} = w^{flex})');
legend('Markup (\mu)', 'Oil price (q)', 'Location', 'best', 'FontSize', 9);
grid on;

% --- (2,2): Unemployment ---
subplot(2,3,5);
plot(quarters, u_mu*100,  '-', 'Color', c_mu,  'LineWidth', 2.0);  hold on;
plot(quarters, u_oil*100, '-', 'Color', c_oil, 'LineWidth', 2.0);
yline(0, 'k:', 'LineWidth', 0.8);
ylabel('Percent deviation');
xlabel('Quarters');
title('Unemployment Rate');
legend('Markup (\mu)', 'Oil price (q)', 'Location', 'best', 'FontSize', 9);
grid on;

% --- (2,3): Dynamic Phillips curve path ---
subplot(2,3,6);
plot(y_mu*100,  pi_mu*400,  '.-', 'Color', c_mu,  'LineWidth', 1.8, 'MarkerSize', 10);  hold on;
plot(y_oil*100, pi_oil*400, '.-', 'Color', c_oil, 'LineWidth', 1.8, 'MarkerSize', 10);
plot(y_mu(1)*100,  pi_mu(1)*400,  's', 'Color', c_mu,  'MarkerSize', 8, 'MarkerFaceColor', c_mu);
plot(y_oil(1)*100, pi_oil(1)*400, 's', 'Color', c_oil, 'MarkerSize', 8, 'MarkerFaceColor', c_oil);
yline(0, 'k:', 'LineWidth', 0.5);
xline(0, 'k:', 'LineWidth', 0.5);
xlabel('Output Gap (%)');
ylabel('Inflation (annualized, pp)');
title('Dynamic Phillips Curve Path (\pi vs y)');
legend('Markup (\mu)', 'Oil price (q)', 'Location', 'best', 'FontSize', 9);
grid on;

sgtitle('Structural Twist: Supply Shocks in Normal Times (BE 2025 — no wage norm binding)', ...
        'FontSize', 12, 'FontWeight', 'bold');

exportgraphics(fig2, '/Users/hiro/Desktop/nonlinear_labour/be_model/fig_structural_twist_supply.pdf', ...
               'Resolution', 300);
fprintf('Figure 2 saved: fig_structural_twist_supply.pdf\n');

%% 7. Figure 3: Static AS Curve — Twist vs. Original Inverse-L
% =========================================================================
% Constructs the static AS curve numerically using a fixed-point iteration
% on the reduced-form mapping Y -> (theta, w_new) -> pi.
%
% The Markov two-state approximation (shock persistence tau = 0.8) implies:
%   E_t pi_{t+1} = tau * pi_t  =>  pi = phi_pc * alpha * w_new / (1 - beta*tau)
%
% Static system (all shocks = 0, w_ex(-1) = 0):
%   Production:     n = (1/alpha) * y
%   Unemployment:   u = -z_u * (1-eta) * th
%   Employment-LF:  n = f - cu*u  =>  f = n + cu*u
%   Participation:  omega*f = c1s*w_ex + csu*w_new - cu*u
%   Wage norm:      w_ex = lambda*(tau-1)*pi + (1-lambda)*eta*th
%   Flex wage:      w_flex = eta * th
%   Regime:
%     NORMAL   (th >= theta_low): w_new = w_flex  [participation eq. uses csu*w_flex]
%     BINDING  (th <  theta_low): w_new = w_ex    [participation eq. uses (c1s+csu)*w_ex]
%   Phillips:  pi = phi_pc * alpha * w_new / (1 - beta*tau)
%
% The iteration couples pi and th because w_ex depends on pi.
%
% IMPORTANT: The twist logic is the mirror of the original structural model.
%   Original:  th <= theta_star => binding (slack market, wage norm applies)
%              th >  theta_star => normal  (tight market, flexible wage applies)
%   Twist:     th >= theta_low  => normal  (normal times, flexible wage)
%              th <  theta_low  => binding (deep recession, wage norm constrains)

tau = 0.8;    % Markov shock persistence
delta_tau_1 = tau - 1;  % delta_w * tau - 1 = 1.0*0.8 - 1 = -0.2

% Grid for output gap (wide enough to capture both regimes)
y_grid = linspace(-0.06, 0.04, 500);
pi_as_twist = zeros(size(y_grid));

for jj = 1:length(y_grid)
    yval = y_grid(jj);

    % Production: employment deviation given output deviation (a_shock = 0)
    nval = (1/alpha_val) * yval;

    % Fixed-point iteration on pi (scalar)
    pi_iter = 0;

    for iter = 1:200

        % Step 1: Solve for labor market tightness (th) given nval and pi_iter.
        %
        % We solve separately for each regime, then check which is consistent.
        %
        % Both regimes share:
        %   u = -z_u * (1-eta) * th
        %   f = nval + cu_val * z_u_val * (1-eta_val) * th  [from n = f - cu*u]
        %   w_ex = lambda_val*pi_iter*delta_tau_1 + (1-lambda_val)*eta_val*th
        %
        % Participation equation: omega*f + 0 = c1s*w_ex + csu*w_new - cu*u
        % Substitute f and u:
        %   omega*(nval + cu*z_u*(1-eta)*th) = c1s*w_ex + csu*w_new - cu*(-z_u*(1-eta)*th)
        %   omega*nval + (omega*cu + cu)*z_u*(1-eta)*th = c1s*w_ex + csu*w_new
        %   omega*nval + (omega+1)*cu*z_u*(1-eta)*th = c1s*w_ex + csu*w_new

        % --- BINDING regime attempt: w_new = w_ex = lambda*(tau-1)*pi + (1-lambda)*eta*th ---
        % Participation: omega*nval + (omega+1)*cu*z_u*(1-eta)*th
        %              = (c1s+csu)*[lambda*(tau-1)*pi + (1-lambda)*eta*th]
        % Rearranging for th:
        %   [(omega+1)*cu*z_u*(1-eta) + (c1s+csu)*(1-lambda)*eta] * th
        %   = omega*nval - (c1s+csu)*lambda*pi*(tau-1)
        %   [Note: (tau-1) is negative; delta_tau_1 = tau - 1]
        A_bind = (omega_val + 1) * cu_val * z_u_val * (1-eta_val) ...
               + (c1s_val + csu_val) * (1-lambda_val) * eta_val;
        B_bind = (c1s_val + csu_val) * lambda_val * pi_iter * delta_tau_1;
        th_bind = (omega_val * nval - B_bind) / A_bind;

        % --- NORMAL regime attempt: w_new = w_flex = eta*th ---
        % Participation: omega*nval + (omega+1)*cu*z_u*(1-eta)*th
        %              = c1s*[lambda*(tau-1)*pi + (1-lambda)*eta*th] + csu*eta*th
        % Rearranging:
        %   [(omega+1)*cu*z_u*(1-eta) + c1s*(1-lambda)*eta + csu*eta] * th
        %   = omega*nval - c1s*lambda*pi*(tau-1)
        A_norm = (omega_val + 1) * cu_val * z_u_val * (1-eta_val) ...
               + c1s_val * (1-lambda_val) * eta_val ...
               + csu_val * eta_val;
        B_norm = c1s_val * lambda_val * pi_iter * delta_tau_1;
        th_norm = (omega_val * nval - B_norm) / A_norm;

        % Regime selection: TWIST logic
        %   If th_norm >= theta_low => use normal regime (w_new = w_flex)
        %   If th_norm <  theta_low => binding; check th_bind for consistency
        if th_norm >= th_low_val
            % Normal regime: w_new = w_flex = eta * th_norm
            th_use = th_norm;
            wn_use = eta_val * th_use;
        else
            % Deep recession: wage norm may bind.
            % Check th_bind: if th_bind < theta_low, binding regime is self-consistent.
            if th_bind < th_low_val
                th_use = th_bind;
                wn_use = lambda_val * pi_iter * delta_tau_1 ...
                       + (1-lambda_val) * eta_val * th_use;
            else
                % Inconsistent: th_bind landed above theta_low. Use normal regime
                % (transition zone — wage norm does not actually bind at this y).
                th_use = th_norm;
                wn_use = eta_val * th_use;
            end
        end

        % Phillips curve: pi = phi_pc * alpha * w_new / (1 - beta_disc * tau)
        pi_new = phi_pc_val * alpha_val * wn_use / (1 - beta_val * tau);

        % Check convergence
        if abs(pi_new - pi_iter) < 1e-13
            break;
        end
        pi_iter = pi_new;
    end

    pi_as_twist(jj) = pi_new;
end

% ---- Original structural model AS curve (for reference) ----
% Uses the same parameter set but with ORIGINAL regime logic:
%   theta <= theta_star => binding (slack market, wage norm: w_new = w_ex)
%   theta >  theta_star => normal  (tight market, flexible wage: w_new = w_flex)
% theta_star in the original model = 0.01
th_star_orig = 0.01;

pi_as_orig = zeros(size(y_grid));

for jj = 1:length(y_grid)
    yval = y_grid(jj);
    nval = (1/alpha_val) * yval;
    pi_iter = 0;

    for iter = 1:200
        A_bind = (omega_val + 1) * cu_val * z_u_val * (1-eta_val) ...
               + (c1s_val + csu_val) * (1-lambda_val) * eta_val;
        B_bind = (c1s_val + csu_val) * lambda_val * pi_iter * delta_tau_1;
        th_bind = (omega_val * nval - B_bind) / A_bind;

        A_norm = (omega_val + 1) * cu_val * z_u_val * (1-eta_val) ...
               + c1s_val * (1-lambda_val) * eta_val ...
               + csu_val * eta_val;
        B_norm = c1s_val * lambda_val * pi_iter * delta_tau_1;
        th_norm = (omega_val * nval - B_norm) / A_norm;

        % Original inverse-L logic:
        %   Tight (th > theta_star): w_new = w_flex
        %   Slack (th <= theta_star): w_new = w_ex
        if th_norm > th_star_orig
            th_use = th_norm;
            wn_use = eta_val * th_use;
        else
            if th_bind <= th_star_orig
                th_use = th_bind;
                wn_use = lambda_val * pi_iter * delta_tau_1 ...
                       + (1-lambda_val) * eta_val * th_use;
            else
                th_use = th_norm;
                wn_use = eta_val * th_use;
            end
        end

        pi_new = phi_pc_val * alpha_val * wn_use / (1 - beta_val * tau);
        if abs(pi_new - pi_iter) < 1e-13
            break;
        end
        pi_iter = pi_new;
    end
    pi_as_orig(jj) = pi_new;
end

% ---- Plot Figure 3 ----
fig3 = figure('Name', 'Static AS Curve: Structural Twist vs Inverse-L', ...
              'Position', [100 100 880 620]);

% A_norm_const: coefficient in the normal-regime participation equation for theta.
% Depends only on structural parameters (not on y or pi), so it is constant.
A_norm_const = (omega_val + 1) * cu_val * z_u_val * (1-eta_val) ...
             + c1s_val * (1-lambda_val) * eta_val ...
             + csu_val * eta_val;

% Approximate y at which theta crosses theta_low (first-order approximation):
%   In normal regime with pi~0: th ~ (omega/A_norm_const) * (1/alpha) * y
%   => y_kink ~ th_low * A_norm_const * alpha / omega
y_kink_approx = th_low_val * A_norm_const * alpha_val / omega_val;

% Plot as one continuous curve (segmentation is implicit via the iteration logic).
plot(y_grid*100, pi_as_twist*400 + 2, 'b-',  'LineWidth', 2.8);  hold on;
plot(y_grid*100, pi_as_orig*400  + 2, 'r--', 'LineWidth', 2.5);

% Mark the kink point on the twist curve (dot at y_kink_approx)
[~, kink_t_idx] = min(abs(y_grid - y_kink_approx));
if kink_t_idx > 1 && kink_t_idx < length(y_grid)
    plot(y_grid(kink_t_idx)*100, pi_as_twist(kink_t_idx)*400 + 2, ...
         'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');
end
xline(y_kink_approx*100, 'b:', 'LineWidth', 1.5);
text(y_kink_approx*100 + 0.1, 1.5, ...
     sprintf('\\theta = \\theta_{low}\n(twist kink)'), ...
     'FontSize', 9, 'Color', 'b', 'HorizontalAlignment', 'left');

% Original model kink near y = 0 (theta_star = 0.01 is small)
xline(0, 'r:', 'LineWidth', 1.5);
text(0.1, 5.5, ...
     sprintf('\\theta > \\theta^* (orig. kink)'), ...
     'FontSize', 9, 'Color', 'r', 'HorizontalAlignment', 'left');

% Inflation target reference
yline(2, 'k:', 'LineWidth', 0.8);

xlabel('Output Gap (%)', 'FontSize', 12);
ylabel('Inflation (annualized, %)', 'FontSize', 12);
title({'Static AS Curve: Structural Twist vs. Inverse-L (BE 2025)', ...
       'Static representation: all shocks = 0, \pi^* = 2%, \tau = 0.8'}, ...
      'FontSize', 12);
legend('Structural Twist AS (flat in deep recession)', ...
       'Original Structural AS (Inverse-L: flat in slack, steep in boom)', ...
       'Location', 'northwest', 'FontSize', 10);
xlim([-6.5 4.5]);
ylim([-1 9]);
grid on;
set(gca, 'FontSize', 11);

exportgraphics(fig3, '/Users/hiro/Desktop/nonlinear_labour/be_model/fig_structural_twist_as_curve.pdf', ...
               'Resolution', 300);
fprintf('Figure 3 saved: fig_structural_twist_as_curve.pdf\n');

%% 8. Figure 4: Missing Disinflation Detail (large recession scenario)
% =========================================================================
% Zooms in on the key empirical prediction: piecewise vs. linear inflation
% paths for Scenario 5 (large recession, eps_g = -0.05).
% Annotates the missing disinflation magnitude at each quarter.

missing_disinfl = (pi_rec - pi_rec_lin) * 400;   % in annualized pp (positive = less deflation)
peak_miss_t = find(missing_disinfl == max(missing_disinfl), 1);

if max(abs(missing_disinfl)) > 0.005
    fig4 = figure('Name', 'Structural Twist: Missing Disinflation Detail', ...
                  'Position', [100 100 900 520]);

    % Panel 1: Inflation comparison
    subplot(1,2,1);
    plot(quarters, pi_rec*400,     '-',  'Color', c_rec, 'LineWidth', 2.5);  hold on;
    plot(quarters, pi_rec_lin*400, '--', 'Color', c_lin, 'LineWidth', 2.0);
    yline(0, 'k:', 'LineWidth', 0.8);
    % Mark peak missing disinflation
    plot([peak_miss_t, peak_miss_t], ...
         [pi_rec_lin(peak_miss_t)*400, pi_rec(peak_miss_t)*400], ...
         'k-', 'LineWidth', 1.5);
    text(peak_miss_t + 0.5, (pi_rec(peak_miss_t) + 0.5*(pi_rec_lin(peak_miss_t)-pi_rec(peak_miss_t)))*400, ...
         sprintf('Peak:\n+%.2f pp', missing_disinfl(peak_miss_t)), ...
         'FontSize', 9, 'Color', 'k', 'HorizontalAlignment', 'left');
    xlabel('Quarters after shock');
    ylabel('Percentage points (annualized)');
    title('Inflation: Piecewise vs. Linear');
    legend('Piecewise (wage norm binds)', 'Linear (no wage norm)', ...
           'Location', 'best', 'FontSize', 9);
    grid on;

    % Panel 2: Missing disinflation gap over time
    subplot(1,2,2);
    bar(quarters, missing_disinfl, 'FaceColor', [0.4 0.6 0.9], 'EdgeColor', 'none');
    hold on;
    yline(0, 'k-', 'LineWidth', 0.8);
    xlabel('Quarters after shock');
    ylabel('Percentage points (annualized)');
    title('Missing Disinflation Gap (\pi_{pw} - \pi_{lin})');
    text(peak_miss_t, missing_disinfl(peak_miss_t) + 0.002*400, ...
         sprintf('%.2f pp', missing_disinfl(peak_miss_t)), ...
         'FontSize', 9, 'HorizontalAlignment', 'center');
    grid on;

    sgtitle({'Structural Twist: Missing Disinflation in Large Recession', ...
             'Scenario 5: eps\_g = -0.05, wage norm binding when \theta < \theta_{low}'}, ...
            'FontSize', 12, 'FontWeight', 'bold');

    exportgraphics(fig4, '/Users/hiro/Desktop/nonlinear_labour/be_model/fig_structural_twist_missing_disinfl.pdf', ...
                   'Resolution', 300);
    fprintf('Figure 4 saved: fig_structural_twist_missing_disinfl.pdf\n');
else
    fprintf('\nNote: Missing disinflation too small to plot (max = %.4f pp). Figure 4 skipped.\n', ...
            max(abs(missing_disinfl)));
end

%% 9. Summary diagnostics
% =========================================================================

fprintf('\n');
fprintf('=======================================================================\n');
fprintf('  BE STRUCTURAL TWIST MODEL — SCENARIO SUMMARY (impact period, t=1)\n');
fprintf('=======================================================================\n');
fprintf('  Parameter: theta_low = %.4f (wage norm binds below this)\n', th_low_val);
fprintf('-----------------------------------------------------------------------\n');

% Scenario 1: small negative demand
fprintf('  Scen 1 — Small neg. demand (eps_g = -0.02, non-binding):\n');
fprintf('    y(1)     = %+.6f  pi(1)    = %+.6f pp (ann.)\n', ...
        results_small_neg.piecewise(1, idx.y), ...
        results_small_neg.piecewise(1, idx.pi)*400);
fprintf('    theta(1) = %+.6f  w_new(1) = %+.6f  u(1) = %+.6f\n', ...
        results_small_neg.piecewise(1, idx.theta), ...
        results_small_neg.piecewise(1, idx.w_new), ...
        results_small_neg.piecewise(1, idx.u_rate));

% Scenario 2: positive demand
fprintf('  Scen 2 — Positive demand (eps_g = +0.05, non-binding):\n');
fprintf('    y(1)     = %+.6f  pi(1)    = %+.6f pp (ann.)\n', ...
        results_pos_demand.piecewise(1, idx.y), ...
        results_pos_demand.piecewise(1, idx.pi)*400);
fprintf('    theta(1) = %+.6f  w_new(1) = %+.6f  u(1) = %+.6f\n', ...
        results_pos_demand.piecewise(1, idx.theta), ...
        results_pos_demand.piecewise(1, idx.w_new), ...
        results_pos_demand.piecewise(1, idx.u_rate));

% Scenario 3: markup shock
fprintf('  Scen 3 — Markup shock (eps_mu = +0.01, non-binding):\n');
fprintf('    y(1)     = %+.6f  pi(1)    = %+.6f pp (ann.)\n', ...
        results_markup.piecewise(1, idx.y), ...
        results_markup.piecewise(1, idx.pi)*400);
fprintf('    theta(1) = %+.6f  w_new(1) = %+.6f  u(1) = %+.6f\n', ...
        results_markup.piecewise(1, idx.theta), ...
        results_markup.piecewise(1, idx.w_new), ...
        results_markup.piecewise(1, idx.u_rate));

% Scenario 4: oil price shock
fprintf('  Scen 4 — Oil price shock (eps_q = +0.10, non-binding):\n');
fprintf('    y(1)     = %+.6f  pi(1)    = %+.6f pp (ann.)\n', ...
        results_oil.piecewise(1, idx.y), ...
        results_oil.piecewise(1, idx.pi)*400);
fprintf('    theta(1) = %+.6f  w_new(1) = %+.6f  u(1) = %+.6f\n', ...
        results_oil.piecewise(1, idx.theta), ...
        results_oil.piecewise(1, idx.w_new), ...
        results_oil.piecewise(1, idx.u_rate));

% Scenario 5: large recession
fprintf('  Scen 5 — Large recession (eps_g = -0.05, wage norm BINDING):\n');
fprintf('    y(1)     = %+.6f  pi(1)    = %+.6f pp (piecewise)\n', ...
        results_recession.piecewise(1, idx.y), ...
        results_recession.piecewise(1, idx.pi)*400);
fprintf('    pi(1)_lin= %+.6f pp (linear counterfactual)\n', ...
        results_recession.linear(1, idx.pi)*400);
fprintf('    Missing disinflation: %+.4f pp (piecewise minus linear)\n', ...
        (results_recession.piecewise(1, idx.pi) - results_recession.linear(1, idx.pi))*400);
fprintf('    theta(1) = %+.6f  w_new(1) = %+.6f  u(1) = %+.6f\n', ...
        results_recession.piecewise(1, idx.theta), ...
        results_recession.piecewise(1, idx.w_new), ...
        results_recession.piecewise(1, idx.u_rate));

% Scenario 6: recession + markup
fprintf('  Scen 6 — Recession + markup (eps_g=-0.05, eps_mu=+0.01, BINDING):\n');
fprintf('    y(1)     = %+.6f  pi(1)    = %+.6f pp (piecewise)\n', ...
        results_rec_markup.piecewise(1, idx.y), ...
        results_rec_markup.piecewise(1, idx.pi)*400);
fprintf('    Markup add-on (piecewise): %+.4f pp\n', ...
        (results_rec_markup.piecewise(1, idx.pi) - results_recession.piecewise(1, idx.pi))*400);
fprintf('    Markup add-on (linear):   %+.4f pp\n', ...
        (results_rec_markup.linear(1, idx.pi) - results_recession.linear(1, idx.pi))*400);

fprintf('=======================================================================\n');
fprintf('All simulations and plots completed.\n');
fprintf('Figures: fig_structural_twist_demand_asymmetry.pdf\n');
fprintf('         fig_structural_twist_supply.pdf\n');
fprintf('         fig_structural_twist_as_curve.pdf\n');
fprintf('         fig_structural_twist_missing_disinfl.pdf  (if applicable)\n');
