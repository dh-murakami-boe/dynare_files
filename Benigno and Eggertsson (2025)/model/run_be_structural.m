%% run_be_structural.m
% =========================================================================
% Driver script for the Benigno & Eggertsson (2025) full structural model
% with search-and-matching labor market and nonlinear Phillips curve.
%
% This script:
%   1. Runs the Dynare model (incl. OccBin scenarios)
%   2. Plots OccBin impulse responses for demand shocks (+ vs -)
%   3. Plots labor market IRFs (matching and separation shocks)
%   4. Plots supply shock IRFs (markup and oil)
%   5. Plots the Inverse-L Phillips curve in (Y, pi) space
%
% Requirements: MATLAB R2025b, Dynare 6.5
% =========================================================================

clear; close all; clc;

%% 1. Run Dynare model (includes OccBin scenarios via occbin_solver)
% =========================================================================
dynare be_structural noclearall;

global M_ oo_ options_;

%% 2. Extract variable indices
% =========================================================================

var_names = M_.endo_names;
idx = struct();
idx.y      = strmatch('y',        var_names, 'exact');
idx.pi     = strmatch('pi',       var_names, 'exact');
idx.ii     = strmatch('ii',       var_names, 'exact');
idx.theta  = strmatch('theta',    var_names, 'exact');
idx.w_new  = strmatch('w_new',    var_names, 'exact');
idx.w_ex   = strmatch('w_ex',     var_names, 'exact');
idx.w_flex = strmatch('w_flex',   var_names, 'exact');
idx.n_emp  = strmatch('n_emp',    var_names, 'exact');
idx.f_lf   = strmatch('f_lf',    var_names, 'exact');
idx.u_rate = strmatch('u_rate',   var_names, 'exact');

% Simulation horizon
T_simul = 40;
quarters = 1:T_simul;

%% 3. Figure 1: Asymmetric Demand Shocks (positive vs negative)
% =========================================================================
% Compares the response to a positive demand shock (triggers tight regime)
% vs a negative demand shock (stays in slack regime).

figure('Name', 'Demand Shock: Asymmetric IRFs', 'Position', [50 50 1100 800]);

% Extract piecewise and linear IRFs
y_pos  = results_demand.piecewise(:, idx.y);
pi_pos = results_demand.piecewise(:, idx.pi);
th_pos = results_demand.piecewise(:, idx.theta);
wn_pos = results_demand.piecewise(:, idx.w_new);
wx_pos = results_demand.piecewise(:, idx.w_ex);
u_pos  = results_demand.piecewise(:, idx.u_rate);

y_neg  = results_neg_demand.piecewise(:, idx.y);
pi_neg = results_neg_demand.piecewise(:, idx.pi);
th_neg = results_neg_demand.piecewise(:, idx.theta);
wn_neg = results_neg_demand.piecewise(:, idx.w_new);
wx_neg = results_neg_demand.piecewise(:, idx.w_ex);
u_neg  = results_neg_demand.piecewise(:, idx.u_rate);

% Linear (no regime switch) for comparison
y_pos_lin  = results_demand.linear(:, idx.y);
pi_pos_lin = results_demand.linear(:, idx.pi);

subplot(3,2,1);
plot(quarters, y_pos*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, y_neg*100, 'r--', 'LineWidth', 2);
plot(quarters, y_pos_lin*100, 'b:', 'LineWidth', 1.5);
yline(0, 'k:', 'LineWidth', 0.5);
title('Output Gap');
ylabel('Percent');
legend('Positive (piecewise)', 'Negative (piecewise)', ...
       'Positive (linear)', 'Location', 'best');
grid on;

subplot(3,2,2);
plot(quarters, pi_pos*400, 'b-', 'LineWidth', 2); hold on;
plot(quarters, pi_neg*400, 'r--', 'LineWidth', 2);
plot(quarters, pi_pos_lin*400, 'b:', 'LineWidth', 1.5);
title('Inflation (annualized)');
ylabel('Percentage points');
grid on;

subplot(3,2,3);
plot(quarters, th_pos*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, th_neg*100, 'r--', 'LineWidth', 2);
yline(0, 'k:', '\theta^*', 'LineWidth', 1);
title('Labor Market Tightness');
ylabel('Percent dev.');
grid on;

subplot(3,2,4);
plot(quarters, wn_pos*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, wn_neg*100, 'r--', 'LineWidth', 2);
plot(quarters, wx_pos*100, 'b-.', 'LineWidth', 1.5);
plot(quarters, wx_neg*100, 'r-.', 'LineWidth', 1.5);
title('Wages');
ylabel('Percent dev.');
legend('w^{new} (+)', 'w^{new} (-)', 'w^{ex} (+)', 'w^{ex} (-)', ...
       'Location', 'best');
grid on;

subplot(3,2,5);
plot(quarters, u_pos*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, u_neg*100, 'r--', 'LineWidth', 2);
title('Unemployment Rate');
ylabel('Percent dev.');
xlabel('Quarters');
grid on;

subplot(3,2,6);
% Dynamic Phillips curve path in (Y, pi) space
plot(y_pos*100, pi_pos*400, 'b.-', 'LineWidth', 1.5, 'MarkerSize', 10); hold on;
plot(y_neg*100, pi_neg*400, 'r.--', 'LineWidth', 1.5, 'MarkerSize', 10);
title('Phillips Curve (dynamic path)');
xlabel('Output Gap (%)');
ylabel('Inflation (ann., pp)');
legend('Positive shock', 'Negative shock', 'Location', 'best');
grid on;

sgtitle('BE (2025) Structural Model: Asymmetric Demand Shock Responses');
exportgraphics(gcf, 'fig_structural_demand_asymmetry.pdf');

%% 4. Figure 2: Labor Market Shocks
% =========================================================================
% Shows the response to matching efficiency and separation rate shocks.
% These are unique to the structural model (no simplified-model analogue).

figure('Name', 'Labor Market Shocks', 'Position', [50 50 1100 800]);

% Matching efficiency shock
y_match  = results_matching.piecewise(:, idx.y);
pi_match = results_matching.piecewise(:, idx.pi);
th_match = results_matching.piecewise(:, idx.theta);
wn_match = results_matching.piecewise(:, idx.w_new);
wx_match = results_matching.piecewise(:, idx.w_ex);
u_match  = results_matching.piecewise(:, idx.u_rate);
n_match  = results_matching.piecewise(:, idx.n_emp);
f_match  = results_matching.piecewise(:, idx.f_lf);

% Separation rate shock
y_sep  = results_separation.piecewise(:, idx.y);
pi_sep = results_separation.piecewise(:, idx.pi);
th_sep = results_separation.piecewise(:, idx.theta);
wn_sep = results_separation.piecewise(:, idx.w_new);
wx_sep = results_separation.piecewise(:, idx.w_ex);
u_sep  = results_separation.piecewise(:, idx.u_rate);
n_sep  = results_separation.piecewise(:, idx.n_emp);
f_sep  = results_separation.piecewise(:, idx.f_lf);

subplot(3,2,1);
plot(quarters, th_match*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, th_sep*100, 'r--', 'LineWidth', 2);
yline(0, 'k:', 'LineWidth', 0.5);
title('Labor Market Tightness');
ylabel('Percent dev.');
legend('Matching eff. (-)', 'Separation rate (+)', 'Location', 'best');
grid on;

subplot(3,2,2);
plot(quarters, u_match*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, u_sep*100, 'r--', 'LineWidth', 2);
title('Unemployment Rate');
ylabel('Percent dev.');
grid on;

subplot(3,2,3);
plot(quarters, wn_match*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, wn_sep*100, 'r--', 'LineWidth', 2);
plot(quarters, wx_match*100, 'b-.', 'LineWidth', 1.5);
plot(quarters, wx_sep*100, 'r-.', 'LineWidth', 1.5);
title('Wages');
ylabel('Percent dev.');
legend('w^{new} (match)', 'w^{new} (sep)', ...
       'w^{ex} (match)', 'w^{ex} (sep)', 'Location', 'best');
grid on;

subplot(3,2,4);
plot(quarters, y_match*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, y_sep*100, 'r--', 'LineWidth', 2);
title('Output Gap');
ylabel('Percent');
grid on;

subplot(3,2,5);
plot(quarters, pi_match*400, 'b-', 'LineWidth', 2); hold on;
plot(quarters, pi_sep*400, 'r--', 'LineWidth', 2);
title('Inflation (annualized)');
ylabel('Percentage points');
xlabel('Quarters');
grid on;

subplot(3,2,6);
plot(quarters, n_match*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, n_sep*100, 'r--', 'LineWidth', 2);
plot(quarters, f_match*100, 'b-.', 'LineWidth', 1.5);
plot(quarters, f_sep*100, 'r-.', 'LineWidth', 1.5);
title('Employment and Participation');
ylabel('Percent dev.');
xlabel('Quarters');
legend('N (match)', 'N (sep)', 'F (match)', 'F (sep)', 'Location', 'best');
grid on;

sgtitle('BE (2025) Structural Model: Labor Market Shock IRFs');
exportgraphics(gcf, 'fig_structural_labor_market.pdf');

%% 5. Figure 3: Supply / Cost-Push Shocks
% =========================================================================

figure('Name', 'Supply Shocks', 'Position', [50 50 1100 550]);

% Markup shock
y_mu  = results_supply.piecewise(:, idx.y);
pi_mu = results_supply.piecewise(:, idx.pi);
th_mu = results_supply.piecewise(:, idx.theta);

% Oil price shock
y_oil  = results_oil.piecewise(:, idx.y);
pi_oil = results_oil.piecewise(:, idx.pi);
th_oil = results_oil.piecewise(:, idx.theta);

subplot(2,3,1);
plot(quarters, y_mu*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, y_oil*100, 'r--', 'LineWidth', 2);
title('Output Gap');
ylabel('Percent');
legend('Markup (\mu)', 'Oil price (q)', 'Location', 'best');
grid on;

subplot(2,3,2);
plot(quarters, pi_mu*400, 'b-', 'LineWidth', 2); hold on;
plot(quarters, pi_oil*400, 'r--', 'LineWidth', 2);
title('Inflation (annualized)');
ylabel('Percentage points');
grid on;

subplot(2,3,3);
plot(quarters, th_mu*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, th_oil*100, 'r--', 'LineWidth', 2);
yline(0, 'k:', 'LineWidth', 0.5);
title('Labor Market Tightness');
ylabel('Percent dev.');
grid on;

subplot(2,3,4);
wn_mu = results_supply.piecewise(:, idx.w_new);
wn_oil = results_oil.piecewise(:, idx.w_new);
plot(quarters, wn_mu*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, wn_oil*100, 'r--', 'LineWidth', 2);
title('New Hire Wage');
ylabel('Percent dev.');
xlabel('Quarters');
grid on;

subplot(2,3,5);
u_mu = results_supply.piecewise(:, idx.u_rate);
u_oil = results_oil.piecewise(:, idx.u_rate);
plot(quarters, u_mu*100, 'b-', 'LineWidth', 2); hold on;
plot(quarters, u_oil*100, 'r--', 'LineWidth', 2);
title('Unemployment Rate');
ylabel('Percent dev.');
xlabel('Quarters');
grid on;

subplot(2,3,6);
% Dynamic Phillips curve path
plot(y_mu*100, pi_mu*400, 'b.-', 'LineWidth', 1.5, 'MarkerSize', 8); hold on;
plot(y_oil*100, pi_oil*400, 'r.--', 'LineWidth', 1.5, 'MarkerSize', 8);
title('Phillips Curve Path');
xlabel('Output Gap (%)');
ylabel('Inflation (ann., pp)');
legend('Markup', 'Oil price', 'Location', 'best');
grid on;

sgtitle('BE (2025) Structural Model: Supply / Cost-Push Shock IRFs');
exportgraphics(gcf, 'fig_structural_supply_shocks.pdf');

%% 6. Figure 4: Static Inverse-L Phillips Curve
% =========================================================================
% Constructs the static AS curve by computing the steady-state relationship
% between output and inflation for different demand shock levels.
%
% In the structural model, the AS curve arises from:
%   pi = phi_pc * (alpha * w_new) + beta * pi  (ignoring supply shocks)
% with the wage/labor market block mapping Y -> theta -> w_new.

% Retrieve parameters
phi_pc_val  = M_.params(strmatch('phi_pc',    M_.param_names, 'exact'));
alpha_val   = M_.params(strmatch('alpha',     M_.param_names, 'exact'));
eta_val     = M_.params(strmatch('eta',       M_.param_names, 'exact'));
omega_val   = M_.params(strmatch('omega',     M_.param_names, 'exact'));
lambda_val  = M_.params(strmatch('lambda_w',  M_.param_names, 'exact'));
beta_val    = M_.params(strmatch('beta_disc', M_.param_names, 'exact'));
sigma_val   = M_.params(strmatch('sigma',     M_.param_names, 'exact'));
phipi_val   = M_.params(strmatch('phi_pi',    M_.param_names, 'exact'));
z_u_val     = M_.params(strmatch('z_u',       M_.param_names, 'exact'));
c1s_val     = M_.params(strmatch('coeff_1s',  M_.param_names, 'exact'));
csu_val     = M_.params(strmatch('coeff_su',  M_.param_names, 'exact'));
cu_val      = M_.params(strmatch('coeff_u',   M_.param_names, 'exact'));
u_bar_val   = M_.params(strmatch('u_bar',     M_.param_names, 'exact'));

tau = 0.8;  % Shock persistence (for static AS-AD analysis)

% Build the static Y -> theta -> pi mapping numerically
% In the static short-run equilibrium (2-period Markov, tau = 0.8):
%   - Shock persists with prob tau, reverts to 0 with prob (1-tau)
%   - In the long run (after reversion), pi_L = 0
%   - In the short run: E pi(+1) = tau * pi_S + (1-tau) * 0 = tau * pi_S
%   - So: pi_S = phi_pc * alpha * w_new_S / (1 - beta * tau)  [tight]
%   - Or:  pi_S involves w_ex(-1) = 0 in the first period (starting from SS)
%
% For the static AS curve, solve the system for a grid of Y values.
%
% Given Y: N = (1/alpha)*Y, and from the labor market block, compute theta,
% then w_flex, then determine regime, then compute pi.

y_grid     = linspace(-0.06, 0.06, 500);
pi_as      = zeros(size(y_grid));
theta_as   = zeros(size(y_grid));  % equilibrium theta_hat for each Y
regime_as  = zeros(size(y_grid));  % 0 = slack, 1 = tight

for j = 1:length(y_grid)
    yval = y_grid(j);

    % Production: N = (1/alpha) * Y  (A = 0 in static analysis)
    nval = (1/alpha_val) * yval;

    % Labor market: solve for theta, u, F simultaneously
    % From u = -z_u*(1-eta)*theta  (s=0, m=0 in static)
    % From N = F - cu*u
    % From participation: omega*F = c1s*w_ex + csu*w_new - cu*u  (chi=0)
    %   where w_ex = (1-lambda)*w_flex = (1-lambda)*eta*theta  [first period, w_ex(-1)=0]
    %   Note: w_ex = lambda*(0 - pi + delta*tau*pi) + (1-lambda)*eta*theta
    %        = lambda*pi*(delta*tau - 1) + (1-lambda)*eta*theta
    %
    % This is a coupled system in (theta, pi). We solve it iteratively.

    % Initialize fixed-point iteration on pi
    pi_guess = 0;
    delta_tau_1 = tau - 1;  % delta_w * tau - 1 = -0.2

    for iter = 1:100
        % Solve for theta_hat given Y and pi_guess.
        %
        % System (static, all shocks = 0, w_ex(-1) = 0):
        %   u = -z_u*(1-eta)*theta_hat
        %   N = F - cu*u  =>  F = N + cu*u = nval - cu*z_u*(1-eta)*theta_hat
        %   w_ex = lambda*pi*(tau-1) + (1-lambda)*eta*theta_hat
        %   w_flex = eta*theta_hat
        %   Participation: omega*F = c1s*w_ex + csu*w_new - cu*u
        %
        % Substituting F and u into participation, theta_hat is the
        % sole unknown (given pi_guess).

        % --- Slack regime: w_new = w_ex ---
        A_slack = (omega_val+1)*cu_val*z_u_val*(1-eta_val) ...
                  + (c1s_val + csu_val)*(1-lambda_val)*eta_val;
        B_slack = (c1s_val + csu_val)*lambda_val*pi_guess*delta_tau_1;
        th_slack = (omega_val*nval - B_slack) / A_slack;

        % Check regime: w_flex <= w_ex?
        wf_check = eta_val * th_slack;
        we_check = lambda_val*pi_guess*delta_tau_1 + (1-lambda_val)*eta_val*th_slack;

        if wf_check <= we_check
            th_val   = th_slack;
            wn_val   = we_check;
            is_tight = false;
        else
            % --- Tight regime: w_new = w_flex = eta*theta ---
            A_tight = (omega_val+1)*cu_val*z_u_val*(1-eta_val) ...
                      + c1s_val*(1-lambda_val)*eta_val + csu_val*eta_val;
            B_tight = c1s_val*lambda_val*pi_guess*delta_tau_1;
            th_val   = (omega_val*nval - B_tight) / A_tight;
            wn_val   = eta_val * th_val;
            is_tight = true;
        end

        % Phillips curve: pi = phi_pc*alpha*w_new / (1 - beta*tau)
        pi_new = phi_pc_val * alpha_val * wn_val / (1 - beta_val * tau);

        if abs(pi_new - pi_guess) < 1e-12
            break;
        end
        pi_guess = pi_new;
    end

    pi_as(j)     = pi_new;
    theta_as(j)  = th_val;
    regime_as(j) = double(is_tight);
end

% --- Numerical slope diagnostics (Task 1: compare to Table B of BE 2025) ---
% Compute d(pi)/d(y) in each regime via finite differences on the AS curve.
% Table B reports quarterly slopes: kappa_slack ~ 0.0065, kappa_tight ~ 0.0736.

% Slack regime: use points at y = -0.04 and y = -0.03 (well below kink)
[~, j_s1] = min(abs(y_grid - (-0.04)));
[~, j_s2] = min(abs(y_grid - (-0.03)));
kappa_slack_q = (pi_as(j_s2) - pi_as(j_s1)) / (y_grid(j_s2) - y_grid(j_s1));

% Tight regime: use points at y = 0.04 and y = 0.05 (well above kink)
[~, j_t1] = min(abs(y_grid - 0.04));
[~, j_t2] = min(abs(y_grid - 0.05));
kappa_tight_q = (pi_as(j_t2) - pi_as(j_t1)) / (y_grid(j_t2) - y_grid(j_t1));

fprintf('\n--- AS CURVE SLOPE DIAGNOSTICS ---\n');
fprintf('Slack regime (y in [-0.04, -0.03]):\n');
fprintf('  kappa_slack (quarterly)   = %.4f   (Table B target: 0.0065)\n', kappa_slack_q);
fprintf('  kappa_slack (annualized)  = %.4f\n', kappa_slack_q * 4);
fprintf('Tight regime (y in [0.04, 0.05]):\n');
fprintf('  kappa_tight (quarterly)   = %.4f   (Table B target: 0.0736)\n', kappa_tight_q);
fprintf('  kappa_tight (annualized)  = %.4f\n', kappa_tight_q * 4);
fprintf('Ratio tight/slack           = %.1f   (Table B: %.1f)\n', ...
        kappa_tight_q / kappa_slack_q, 0.0736 / 0.0065);
fprintf('---------------------------------\n');

% --- Figure 4: Inverse-L AS Curve ---
figure('Name', 'Inverse-L AS Curve (Structural)', 'Position', [100 100 800 600]);

plot(y_grid*100, pi_as*400 + 2, 'b-', 'LineWidth', 2.5); hold on;

% AD curve for reference
ad_coeff = -(1-tau) * sigma_val / (phipi_val - tau);
pi_ad = ad_coeff .* y_grid;
pi_ad_shifted = ad_coeff .* (y_grid - 0.025);

plot(y_grid*100, pi_ad*400 + 2, 'r-', 'LineWidth', 2);
plot(y_grid*100, pi_ad_shifted*400 + 2, 'r--', 'LineWidth', 2);

xlabel('Output Gap (%)');
ylabel('Inflation (annualized, %)');
title('Inverse-L Phillips Curve: Full Structural Model (BE 2025)');
legend('AS (structural)', 'AD', 'AD'' (demand shock)', 'Location', 'northwest');
ylim([-2 12]);
xlim([-6 6]);
grid on;

exportgraphics(gcf, 'fig_structural_inverse_L.pdf');

%% 7. Figure 5: Beveridge Curve
% =========================================================================
% Plots the Beveridge curve (eq. 56 of BE 2025):
%   v = ((s - u) / (m * u^eta))^(1/(1-eta))
% with dynamic OccBin trajectories from the demand shock scenarios.

% --- Steady-state calibration ---
% Normalize theta_bar = 1 => v_bar = u_bar = 0.04
% From eq (56): m_bar = (s_bar - u_bar) / (u_bar^eta * v_bar^(1-eta))
s_bar_val = M_.params(strmatch('s_bar', M_.param_names, 'exact'));
v_bar = u_bar_val;  % v_bar = u_bar when theta_bar = 1
m_bar = (s_bar_val - u_bar_val) / (u_bar_val^eta_val * v_bar^(1 - eta_val));
theta_bar = 1;      % normalization

fprintf('\n--- BEVERIDGE CURVE CALIBRATION ---\n');
fprintf('u_bar = %.4f,  v_bar = %.4f,  theta_bar = %.1f\n', u_bar_val, v_bar, theta_bar);
fprintf('m_bar = %.4f,  s_bar = %.4f,  eta = %.2f\n', m_bar, s_bar_val, eta_val);
fprintf('----------------------------------\n');

% --- Static Beveridge curve ---
u_grid_bev = linspace(0.01, 0.10, 200);
v_static = zeros(size(u_grid_bev));
for j = 1:length(u_grid_bev)
    uj = u_grid_bev(j);
    if s_bar_val > uj  % need s > u for positive vacancies
        v_static(j) = ((s_bar_val - uj) / (m_bar * uj^eta_val))^(1/(1 - eta_val));
    else
        v_static(j) = NaN;
    end
end

% --- Dynamic paths from OccBin demand scenarios ---
% Convert log-deviations to levels: x_level = x_bar * exp(x_hat) ≈ x_bar * (1 + x_hat)
u_pos_lev = u_bar_val * (1 + u_pos);
th_pos_lev = theta_bar * (1 + th_pos);
v_pos_lev = th_pos_lev .* u_pos_lev;

u_neg_lev = u_bar_val * (1 + u_neg);
th_neg_lev = theta_bar * (1 + th_neg);
v_neg_lev = th_neg_lev .* u_neg_lev;

% --- Regime boundary ---
% At theta = theta_star (OccBin threshold, in log-dev), compute (u*, v*)
theta_star_val = M_.params(strmatch('theta_star', M_.param_names, 'exact'));
% From u_hat = -z_u*(1-eta)*theta_hat (static, no shocks)
u_hat_star = -z_u_val * (1 - eta_val) * theta_star_val;
u_star_lev = u_bar_val * (1 + u_hat_star);
th_star_lev = theta_bar * (1 + theta_star_val);
v_star_lev = th_star_lev * u_star_lev;

% --- Plot (two panels: full curve + zoom on dynamic paths) ---
figure('Name', 'Beveridge Curve (Structural)', 'Position', [100 100 1200 550]);
T_plot = min(20, T_simul);  % plot first 20 quarters

% --- Panel 1: Full static Beveridge curve with SS marked ---
subplot(1,2,1);
plot(u_grid_bev * 100, v_static * 100, 'k-', 'LineWidth', 2.5); hold on;
plot(u_bar_val*100, v_bar*100, 'ko', 'MarkerSize', 12, 'LineWidth', 2.5);
text(u_bar_val*100 + 0.2, v_bar*100 + 1.0, 'SS', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Unemployment Rate (%)');
ylabel('Vacancy Rate (%)');
title('Static Beveridge Curve (eq. 56)');
grid on;
xlim([1 8]); ylim([0 12]);

% --- Panel 2: Zoomed view with dynamic OccBin paths ---
subplot(1,2,2);

% Compute zoom limits from the dynamic paths (with padding)
all_u = [u_pos_lev(1:T_plot); u_neg_lev(1:T_plot)] * 100;
all_v = [v_pos_lev(1:T_plot); v_neg_lev(1:T_plot)] * 100;
u_pad = 0.3 * (max(all_u) - min(all_u));
v_pad = 0.3 * (max(all_v) - min(all_v));
u_lo = min(all_u) - u_pad; u_hi = max(all_u) + u_pad;
v_lo = min(all_v) - v_pad; v_hi = max(all_v) + v_pad;

% Zoomed static curve as background
u_zoom = linspace(u_lo/100, u_hi/100, 200);
v_zoom = ((s_bar_val - u_zoom) ./ (m_bar * u_zoom.^eta_val)).^(1/(1 - eta_val));
plot(u_zoom*100, v_zoom*100, 'k-', 'LineWidth', 1.5, 'Color', [0.6 0.6 0.6]); hold on;

% Positive demand path (blue, tight regime)
plot(u_pos_lev(1:T_plot)*100, v_pos_lev(1:T_plot)*100, 'b-', 'LineWidth', 2);

% Negative demand path (red, slack regime)
plot(u_neg_lev(1:T_plot)*100, v_neg_lev(1:T_plot)*100, 'r-', 'LineWidth', 2);

% Steady state
plot(u_bar_val*100, v_bar*100, 'ko', 'MarkerSize', 12, 'LineWidth', 2.5);
text(u_bar_val*100 + 0.08, v_bar*100 + 0.12, 'SS', 'FontSize', 11, 'FontWeight', 'bold');

% Regime boundary
plot(u_star_lev*100, v_star_lev*100, 'k^', 'MarkerSize', 10, 'LineWidth', 2);
text(u_star_lev*100 - 0.15, v_star_lev*100 + 0.1, '\theta^*', ...
     'FontSize', 11, 'HorizontalAlignment', 'right');

% Period markers at t = 1, 4, 8
for tt = [1 4 8]
    plot(u_pos_lev(tt)*100, v_pos_lev(tt)*100, 'bo', 'MarkerSize', 7, ...
         'MarkerFaceColor', 'b', 'LineWidth', 1.5);
    plot(u_neg_lev(tt)*100, v_neg_lev(tt)*100, 'rs', 'MarkerSize', 7, ...
         'MarkerFaceColor', 'r', 'LineWidth', 1.5);
    text(u_pos_lev(tt)*100 + 0.02, v_pos_lev(tt)*100 + 0.07, ...
         sprintf('t=%d', tt), 'FontSize', 8, 'Color', 'b');
end

xlim([u_lo u_hi]); ylim([v_lo v_hi]);
xlabel('Unemployment Rate (%)');
ylabel('Vacancy Rate (%)');
title('Dynamic Paths (demand shocks)');
legend('Static BC', 'Positive demand (+5%)', 'Negative demand (-5%)', ...
       'SS', '\theta^* boundary', 'Location', 'northeast');
grid on;

sgtitle('Beveridge Curve: BE (2025) Structural Model');
exportgraphics(gcf, 'fig_structural_beveridge.pdf');

%% 8. Figure 6: Where does the nonlinearity live?
% =========================================================================
% Shows that the piecewise nonlinearity in BE (2025) lives in the
% theta -> pi mapping (wage pass-through to inflation), NOT in (u, v)
% space (the Beveridge curve).
%
% Panel 1: (theta, pi) — the kink in wage-to-inflation pass-through.
%   Slack: w_new = w_ex ≈ (1-lambda)*eta*theta  =>  low pass-through
%   Tight: w_new = w_flex = eta*theta            =>  full pass-through
%   This ~7.7x difference in dpi/dtheta is the Inverse-L.
%
% Panel 2: Equilibrium scatter on the smooth Beveridge curve.
%   Uses eq. (58): u = s / (1 + m * theta^(1-eta)), v = theta * u.
%   By construction, all equilibria lie on the same BC regardless of
%   regime — the matching function is regime-invariant.

% Compute exact (u, v) levels from theta_as via eq. (58)
theta_lev_as = 1 + theta_as;        % theta_bar = 1
u_lev_as = s_bar_val ./ (1 + m_bar * theta_lev_as.^(1 - eta_val));
v_lev_as = theta_lev_as .* u_lev_as;

is_tight_as = logical(regime_as);
is_slack_as = ~is_tight_as;

% Find the theta value where the regime switches (for visual anchor)
switch_idx = find(diff(regime_as) ~= 0, 1);

figure('Name', 'Nonlinearity location: PC vs BC', 'Position', [100 100 1200 520]);

% --- Panel 1: (theta, pi) — kink lives here ---
subplot(1,2,1);
plot(theta_as(is_slack_as)*100, pi_as(is_slack_as)*400, 'r-', 'LineWidth', 2.5); hold on;
plot(theta_as(is_tight_as)*100, pi_as(is_tight_as)*400, 'b-', 'LineWidth', 2.5);
xline(theta_star_val*100, 'k--', 'LineWidth', 1.5);
text(theta_star_val*100 + 0.3, -1.5, '$\hat{\theta}^*$', ...
     'Interpreter', 'latex', 'FontSize', 12);
xline(0, 'k:', 'LineWidth', 0.5);
xlabel('Labor Market Tightness $\hat{\theta}$ (\%)', 'Interpreter', 'latex');
ylabel('Inflation (annualized, pp)');
title('$(\theta, \pi)$: kink in wage pass-through', 'Interpreter', 'latex');
legend('Slack: $w^{new} = w^{ex}$', 'Tight: $w^{new} = w^{flex}$', ...
       'Interpreter', 'latex', 'Location', 'northwest');
grid on;

% --- Panel 2: Equilibrium scatter on smooth BC ---
% Draw random Y values from a demand shock distribution, map through the
% static AS curve to (u, v), and scatter-plot on the Beveridge curve.
% All equilibria land on the same smooth curve regardless of regime.
subplot(1,2,2);

% Background: smooth static BC
plot(u_grid_bev*100, v_static*100, '-', 'LineWidth', 1.5, 'Color', [0.75 0.75 0.75]); hold on;

% Monte Carlo: draw Y values, map to (u, v) via the AS curve
rng(42);
n_draws = 1000;
sigma_y = 0.02;  % ~2% SD of output gap
y_draws = sigma_y * randn(n_draws, 1);
y_draws = max(min(y_draws, max(y_grid)), min(y_grid));  % clamp to grid

% Interpolate theta from the AS curve for each draw
theta_draws = interp1(y_grid, theta_as, y_draws, 'linear');
regime_draws = interp1(y_grid, regime_as, y_draws, 'nearest');

% Map theta -> (u, v) via eq. (58)
theta_lev_draws = 1 + theta_draws;
u_draws = s_bar_val ./ (1 + m_bar * theta_lev_draws.^(1 - eta_val));
v_draws = theta_lev_draws .* u_draws;

is_slack_draw = regime_draws < 0.5;
is_tight_draw = ~is_slack_draw;

scatter(u_draws(is_slack_draw)*100, v_draws(is_slack_draw)*100, ...
        15, 'r', 'filled', 'MarkerFaceAlpha', 0.4);
scatter(u_draws(is_tight_draw)*100, v_draws(is_tight_draw)*100, ...
        15, 'b', 'filled', 'MarkerFaceAlpha', 0.4);

% Regime boundary point
if ~isempty(switch_idx)
    plot(u_lev_as(switch_idx)*100, v_lev_as(switch_idx)*100, ...
         'k^', 'MarkerSize', 10, 'LineWidth', 2);
end

% Steady state
plot(u_bar_val*100, v_bar*100, 'ko', 'MarkerSize', 10, 'LineWidth', 2);
text(u_bar_val*100 + 0.1, v_bar*100 + 0.25, 'SS', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Unemployment Rate u (%)');
ylabel('Vacancy Rate v (%)');
title('Equilibrium scatter on smooth BC (eq. 58)');
legend('Static BC', 'Slack equilibria', 'Tight equilibria', ...
       '\theta^* boundary', 'SS', 'Location', 'northeast');
grid on;

% Zoom to the region where scatter points live (with padding)
all_u_sc = [u_draws(is_slack_draw); u_draws(is_tight_draw)] * 100;
all_v_sc = [v_draws(is_slack_draw); v_draws(is_tight_draw)] * 100;
u_pad_sc = 0.15 * (max(all_u_sc) - min(all_u_sc));
v_pad_sc = 0.15 * (max(all_v_sc) - min(all_v_sc));
xlim([min(all_u_sc) - u_pad_sc, max(all_u_sc) + u_pad_sc]);
ylim([min(all_v_sc) - v_pad_sc, max(all_v_sc) + v_pad_sc]);

sgtitle('BE (2025): Nonlinearity in Phillips Curve, Not Beveridge Curve');
exportgraphics(gcf, 'fig_structural_pc_vs_bc.pdf');

%% 9. Print Summary Statistics
% =========================================================================

fprintf('\n============================================\n');
fprintf('BE (2025) STRUCTURAL MODEL - SUMMARY\n');
fprintf('============================================\n');
fprintf('Demand shock (+0.05):\n');
fprintf('  y(1) = %.6f,  pi(1) = %.6f\n', y_pos(1), pi_pos(1));
fprintf('  theta(1) = %.6f,  w_new(1) = %.6f\n', th_pos(1), wn_pos(1));
fprintf('  u(1) = %.6f\n', u_pos(1));
fprintf('Demand shock (-0.05):\n');
fprintf('  y(1) = %.6f,  pi(1) = %.6f\n', y_neg(1), pi_neg(1));
fprintf('  theta(1) = %.6f,  w_new(1) = %.6f\n', th_neg(1), wn_neg(1));
fprintf('  u(1) = %.6f\n', u_neg(1));
fprintf('Markup shock (+0.01):\n');
fprintf('  y(1) = %.6f,  pi(1) = %.6f\n', y_mu(1), pi_mu(1));
fprintf('Oil price shock (+0.10):\n');
fprintf('  y(1) = %.6f,  pi(1) = %.6f\n', y_oil(1), pi_oil(1));
fprintf('Matching shock (-0.05):\n');
fprintf('  y(1) = %.6f,  theta(1) = %.6f,  u(1) = %.6f\n', ...
         y_match(1), th_match(1), u_match(1));
fprintf('Separation shock (+0.01):\n');
fprintf('  y(1) = %.6f,  theta(1) = %.6f,  u(1) = %.6f\n', ...
         y_sep(1), th_sep(1), u_sep(1));
fprintf('============================================\n');

fprintf('\n=== All simulations and plots completed ===\n');
fprintf('Figures saved to current directory.\n');
