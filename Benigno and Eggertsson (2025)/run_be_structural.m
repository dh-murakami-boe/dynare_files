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

y_grid = linspace(-0.06, 0.06, 500);
pi_as  = zeros(size(y_grid));

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
            th_val = th_slack;
            wn_val = we_check;
        else
            % --- Tight regime: w_new = w_flex = eta*theta ---
            A_tight = (omega_val+1)*cu_val*z_u_val*(1-eta_val) ...
                      + c1s_val*(1-lambda_val)*eta_val + csu_val*eta_val;
            B_tight = c1s_val*lambda_val*pi_guess*delta_tau_1;
            th_val = (omega_val*nval - B_tight) / A_tight;
            wn_val = eta_val * th_val;
        end

        % Phillips curve: pi = phi_pc*alpha*w_new / (1 - beta*tau)
        pi_new = phi_pc_val * alpha_val * wn_val / (1 - beta_val * tau);

        if abs(pi_new - pi_guess) < 1e-12
            break;
        end
        pi_guess = pi_new;
    end

    pi_as(j) = pi_new;
end

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

%% 7. Print Summary Statistics
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
