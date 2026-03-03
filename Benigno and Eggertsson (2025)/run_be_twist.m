%% run_be_twist.m
% =========================================================================
% Driver script: "Twist" on Benigno & Eggertsson (2025)
% Mirror-image nonlinear Phillips curve with wage norm binding in deep recessions
%
% This script:
%   1. Runs the Dynare model be_twist.mod (includes OccBin scenarios)
%   2. Figure 1: IRF comparison — small recession (N) vs. large recession (R)
%      with piecewise vs. linear counterparts to isolate regime-switching
%   3. Figure 2: Static aggregate supply curve — the "twist" kink shape
%      (normal slope for y >= y_low; near-zero slope for y < y_low)
%      compared with BE's original Inverse-L curve for reference
%
% Requirements: MATLAB R2025b, Dynare 6.5
%
% Reference: Benigno, P. and Eggertsson, G. (2025)
%   "It's Baaack: The Surge in Inflation"
% =========================================================================

clear; close all; clc;

%% 1. Run Dynare model (includes all four OccBin scenarios)
% =========================================================================
% After dynare completes, the following variables are in scope:
%   M_      — model metadata (variable names, parameter values)
%   oo_     — output structure (steady state, OccBin results)
%   options_ — Dynare options
%
% The four scenario structs are set inside verbatim blocks of be_twist.mod:
%   results_normal_neg        — Scenario N: small negative demand shock
%   results_pos               — Scenario P: positive demand shock
%   results_recession         — Scenario R: large recession (wage norm binding)
%   results_supply_recession  — Scenario S: recession + supply shock

dynare be_twist noclearall;

global M_ oo_ options_;

%% 2. Extract variable indices and parameter values
% =========================================================================
% OccBin stores results in oo_.occbin.simul.piecewise (T x nvar matrix).
% Column ordering matches the declaration order in be_twist.mod:
%   col 1 = y, col 2 = pi, col 3 = ii, col 4 = g, col 5 = nu,
%   col 6 = e, col 7 = chi

var_names   = M_.endo_names;
y_idx       = strmatch('y',   var_names, 'exact');
pi_idx      = strmatch('pi',  var_names, 'exact');
ii_idx      = strmatch('ii',  var_names, 'exact');

% Retrieve calibrated parameters for use in static plots
p_names     = M_.param_names;
kap_n       = M_.params(strmatch('kappa_normal',   p_names, 'exact'));
kap_f       = M_.params(strmatch('kappa_flat',     p_names, 'exact'));
kap_vn      = M_.params(strmatch('kappa_v_normal', p_names, 'exact'));
y_low_val   = M_.params(strmatch('y_low',          p_names, 'exact'));
c_wnb_val  = M_.params(strmatch('c_wnb',         p_names, 'exact'));
sig_val     = M_.params(strmatch('sigma',           p_names, 'exact'));
phi_pi_val  = M_.params(strmatch('phi_pi',          p_names, 'exact'));

% For BE reference comparison: retrieve be_simplified parameters if available
% (They will not be in scope unless both .mod files run in the same session.)
% We reconstruct from known values for the static plot.
kap_be_slack  = 0.0065;    % BE Table B col. 2: slack regime
kap_be_tight  = 0.0736;    % BE Table B col. 2: tight regime
y_star_be     = 0.01;      % BE threshold (tight labor market)
c_tilde_be    = (kap_be_tight - kap_be_slack) * y_star_be;

% Simulation horizon
T_simul   = 20;
quarters  = 1:T_simul;

%% 3. Extract scenario IRFs
% =========================================================================
% Scenario N: small negative demand (non-binding)
y_N  = results_normal_neg.piecewise(:, y_idx);
pi_N = results_normal_neg.piecewise(:, pi_idx);
ii_N = results_normal_neg.piecewise(:, ii_idx);

% Scenario P: positive demand (non-binding, reference regime throughout)
y_P  = results_pos.piecewise(:, y_idx);
pi_P = results_pos.piecewise(:, pi_idx);
ii_P = results_pos.piecewise(:, ii_idx);

% Scenario R: large recession (wage norm binding)
y_R      = results_recession.piecewise(:, y_idx);
pi_R     = results_recession.piecewise(:, pi_idx);
ii_R     = results_recession.piecewise(:, ii_idx);
y_R_lin  = results_recession.linear(:, y_idx);     % counterfactual linear
pi_R_lin = results_recession.linear(:, pi_idx);

% Scenario S: recession + supply shock (wage norm binding)
y_S  = results_supply_recession.piecewise(:, y_idx);
pi_S = results_supply_recession.piecewise(:, pi_idx);
ii_S = results_supply_recession.piecewise(:, ii_idx);

%% 4. Figure 1: IRF comparison — small recession (N) vs. large recession (R)
% =========================================================================
% This figure illustrates the key nonlinear prediction of the twist model:
% despite a much larger output contraction in Scenario R, inflation barely
% falls more than in Scenario N (missing disinflation). The linear model
% (dashed) predicts proportional disinflation, while the piecewise model
% (solid) shows the wage norm floor.
%
% Subplot layout:
%   (1,1) Output gap paths        — shows the magnitude of contraction
%   (1,2) Inflation paths         — key plot: missing disinflation visible
%   (2,1) Interest rate paths     — policy response to inflation signal
%   (2,2) Dynamic Phillips curve  — (pi, y) scatter: flat vs. normal slope

fig1 = figure('Name', 'Twist Model: Recession Comparison', ...
               'Position', [80 80 1000 760]);

% --- Subplot (1,1): Output gap ---
ax1 = subplot(2, 2, 1);
plot(quarters, y_R*100, 'b-',  'LineWidth', 2.2);   hold on;
plot(quarters, y_N*100, 'r--', 'LineWidth', 2.2);
plot(quarters, y_R_lin*100, 'b:', 'LineWidth', 1.6);
yline(y_low_val*100, 'k-.', 'LineWidth', 1.2);
xline(1, 'k:', 'LineWidth', 0.8);
ylabel('Percent deviation');
xlabel('Quarters after shock');
title('Output Gap');
legend('Large recession R (piecewise)', ...
       'Small recession N (piecewise)', ...
       'Large recession R (linear)', ...
       ['y_{low} = ' num2str(y_low_val*100) '%'], ...
       'Location', 'southeast', 'FontSize', 9);
grid on;
ax1.XLim = [1 T_simul];

% --- Subplot (1,2): Inflation ---
% The critical plot: Scenario R generates massive output decline but
% minimal additional disinflation relative to Scenario N (wage norm floor).
% The linear R path shows what a standard model would predict.
ax2 = subplot(2, 2, 2);
plot(quarters, pi_R*400,     'b-',  'LineWidth', 2.2);   hold on;
plot(quarters, pi_N*400,     'r--', 'LineWidth', 2.2);
plot(quarters, pi_R_lin*400, 'b:',  'LineWidth', 1.6);
yline(0, 'k:', 'LineWidth', 0.8);
xline(1, 'k:', 'LineWidth', 0.8);
ylabel('Percentage points (annualized)');
xlabel('Quarters after shock');
title('Inflation (annualized)');
legend('Large recession R (piecewise)', ...
       'Small recession N (piecewise)', ...
       'Large recession R (linear — no wage norm constraint)', ...
       'Location', 'best', 'FontSize', 9);
grid on;
ax2.XLim = [1 T_simul];

% Add annotation highlighting missing disinflation
% (difference between linear and piecewise at impact)
gap_pp = (pi_R_lin(1) - pi_R(1)) * 400;
if abs(gap_pp) > 0.01
    text(2, pi_R(1)*400 + 0.05, ...
         sprintf('Missing disinfl.\n\\Delta\\pi \\approx %.2f pp', gap_pp), ...
         'FontSize', 8, 'Color', [0.2 0.2 0.8], 'HorizontalAlignment', 'left');
end

% --- Subplot (2,1): Nominal interest rate ---
ax3 = subplot(2, 2, 3);
plot(quarters, ii_R*400, 'b-',  'LineWidth', 2.2);   hold on;
plot(quarters, ii_N*400, 'r--', 'LineWidth', 2.2);
yline(0, 'k:', 'LineWidth', 0.8);
xline(1, 'k:', 'LineWidth', 0.8);
ylabel('Percentage points (annualized)');
xlabel('Quarters after shock');
title('Nominal Interest Rate (Taylor rule)');
legend('Large recession R', 'Small recession N', ...
       'Location', 'best', 'FontSize', 9);
grid on;
ax3.XLim = [1 T_simul];

% --- Subplot (2,2): Dynamic Phillips curve scatter ---
% Traces (y_t, pi_t) paths over T_simul quarters for each scenario.
% Scenario N traces a path with normal slope near origin.
% Scenario R traces a path that enters the flat (wage norm binding) region for y < y_low,
% then recovers along the normal-slope segment as the wage norm constraint eventually relaxes.
% The kink at y = y_low is the key visual feature.
ax4 = subplot(2, 2, 4);
% Plot static PC shape as background reference
y_bg = linspace(-0.05, 0.05, 600);
pc_ref  = kap_n * y_bg;                                          % reference regime
pc_con  = c_wnb_val + kap_f * y_bg;                             % constrained regime
pc_bg                      = pc_ref;
pc_bg(y_bg < y_low_val)    = pc_con(y_bg < y_low_val);
plot(y_bg*100, pc_bg*400, 'k-', 'LineWidth', 0.8, ...
     'Color', [0.7 0.7 0.7]);   hold on;
% Mark kink
xline(y_low_val*100, 'k-.', 'LineWidth', 1.0);
% Dynamic paths
plot(y_R*100, pi_R*400, 'b.-',  'LineWidth', 1.8, 'MarkerSize', 11);
plot(y_N*100, pi_N*400, 'r.--', 'LineWidth', 1.8, 'MarkerSize', 11);
% Mark impact period
plot(y_R(1)*100, pi_R(1)*400, 'bs', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
plot(y_N(1)*100, pi_N(1)*400, 'rs', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
xlabel('Output Gap (%)');
ylabel('Inflation (annualized, pp)');
title('Dynamic Phillips Curve Paths (\pi vs y)');
legend('Static PC (twist shape)', ['y_{low} = ' num2str(y_low_val*100) '%'], ...
       'Large recession R', 'Small recession N', ...
       'Location', 'best', 'FontSize', 9);
grid on;

sgtitle({'Benigno-Eggertsson (2025) Twist: Wage Norm Binding and Missing Disinflation', ...
         'Small recession (N, eps\_d=-0.003) vs. Moderate recession (R, eps\_d=-0.03)'}, ...
        'FontSize', 12, 'FontWeight', 'bold');

exportgraphics(fig1, 'fig_twist_recession_comparison.pdf', 'Resolution', 300);
fprintf('\nFigure 1 saved: fig_twist_recession_comparison.pdf\n');

%% 5. Figure 2: Aggregate Supply curve shape — "twist" kink vs. BE Inverse-L
% =========================================================================
% This figure plots the static AS curve (steady-state PC, holding
% inflation expectations at target and chi = nu = 0) to visualize:
%   (a) The "twist" shape: normal slope for y >= y_low, near-flat for y < y_low
%   (b) The original BE Inverse-L: near-flat for y <= y_star, steep for y > y_star
%
% Both curves are shown in (pi, y) space (annualized inflation, % output gap).
% The curves are drawn using the Markov two-state approximation for the static
% AS (dividing by (1 - tau) where tau = 0.8 is shock persistence), consistent
% with the AS-AD representation in be_simplified's run script.
%
% The two nonlinearities are in opposite corners of the diagram:
%   BE Inv-L:  steep at top-right (tight boom), flat at bottom-left (slack)
%   Twist:     normal at top-right (normal times), flat at far bottom-left
%              (deep recession) — kink at y_low rather than y_star.

tau = 0.8;   % Shock persistence (Markov tau from paper)

y_grid = linspace(-0.05, 0.06, 800);

% --- Twist AS curve (this model) ---
% Reference regime:   pi = kappa_normal / (1-tau) * y
% Constrained regime: pi = c_wnb / (1-tau) + kappa_flat / (1-tau) * y
% (Static: nu = chi = 0, expectations at target => pi(+1) absorbed in (1-tau))
as_twist_ref  = (kap_n / (1-tau)) .* y_grid;
as_twist_con  = (c_wnb_val / (1-tau)) + (kap_f / (1-tau)) .* y_grid;
as_twist      = as_twist_ref;
as_twist(y_grid < y_low_val) = as_twist_con(y_grid < y_low_val);

% --- BE original Inverse-L AS curve (for reference) ---
% Slack regime:  pi = kappa_be_slack / (1-tau) * y       (y <= y_star)
% Tight regime:  pi = -c_tilde_be / (1-tau) + kappa_be_tight / (1-tau) * y  (y > y_star)
as_be_slack = (kap_be_slack / (1-tau)) .* y_grid;
as_be_tight = -(c_tilde_be / (1-tau)) + (kap_be_tight / (1-tau)) .* y_grid;
as_be       = as_be_slack;
as_be(y_grid > y_star_be) = as_be_tight(y_grid > y_star_be);

% --- Plot ---
fig2 = figure('Name', 'AS Curve: Twist vs. BE Inverse-L', ...
               'Position', [100 100 820 600]);

% Twist: reference regime segment
idx_ref = y_grid >= y_low_val;
idx_con = y_grid <  y_low_val;

h1 = plot(y_grid(idx_ref)*100, as_twist(idx_ref)*400 + 2, ...
          'b-', 'LineWidth', 2.5);   hold on;
h2 = plot(y_grid(idx_con)*100, as_twist(idx_con)*400 + 2, ...
          'b--', 'LineWidth', 2.5);

% Kink point for twist
[~, kink_idx] = min(abs(y_grid - y_low_val));
plot(y_grid(kink_idx)*100, as_twist(kink_idx)*400 + 2, ...
     'bo', 'MarkerSize', 9, 'MarkerFaceColor', 'b');

% BE Inverse-L: slack segment
idx_be_slack = y_grid <= y_star_be;
idx_be_tight = y_grid >  y_star_be;
h3 = plot(y_grid(idx_be_slack)*100, as_be(idx_be_slack)*400 + 2, ...
          'r-', 'LineWidth', 2.0);
h4 = plot(y_grid(idx_be_tight)*100, as_be(idx_be_tight)*400 + 2, ...
          'r-', 'LineWidth', 2.0);

% Kink point for BE
[~, kink_be_idx] = min(abs(y_grid - y_star_be));
plot(y_grid(kink_be_idx)*100, as_be(kink_be_idx)*400 + 2, ...
     'ro', 'MarkerSize', 9, 'MarkerFaceColor', 'r');

% Threshold lines
xline(y_low_val*100, 'b:', 'LineWidth', 1.4);
xline(y_star_be*100, 'r:', 'LineWidth', 1.4);
yline(2, 'k:', 'LineWidth', 0.8);    % 2% inflation target

% Annotations
text(y_low_val*100 - 0.4, as_twist(kink_idx)*400 + 2 - 0.4, ...
     sprintf('y_{low} = %.1f%%', y_low_val*100), ...
     'FontSize', 9, 'Color', 'b', 'HorizontalAlignment', 'right');
text(y_star_be*100 + 0.1, as_be(kink_be_idx)*400 + 2 + 0.2, ...
     sprintf('y^* = %.0f%%', y_star_be*100), ...
     'FontSize', 9, 'Color', 'r', 'HorizontalAlignment', 'left');

% Region labels
text(-3.5, 1.5, {'Wage norm binding', '(twist: flat PC)'}, ...
     'FontSize', 9, 'Color', 'b', 'FontAngle', 'italic', ...
     'HorizontalAlignment', 'left');
text(3.5, 5.5, {'Tight labor mkt', '(BE: steep PC)'}, ...
     'FontSize', 9, 'Color', 'r', 'FontAngle', 'italic', ...
     'HorizontalAlignment', 'left');
text(2.0, 2.5, {'Normal times', '(twist: mod. slope)'}, ...
     'FontSize', 9, 'Color', 'b', 'FontAngle', 'italic', ...
     'HorizontalAlignment', 'left');
text(-3.5, 3.5, {'Slack mkt', '(BE: flat PC)'}, ...
     'FontSize', 9, 'Color', 'r', 'FontAngle', 'italic', ...
     'HorizontalAlignment', 'left');

xlabel('Output Gap (%)', 'FontSize', 12);
ylabel('Inflation (annualized, %)', 'FontSize', 12);
title({'Aggregate Supply Curves: Twist vs. BE (2025) Inverse-L', ...
       'Static representation: \nu = \chi = 0, \pi^* = 2%'}, ...
      'FontSize', 12);
legend([h1, h2, h3], ...
       'Twist: normal regime (y \geq y_{low})', ...
       'Twist: Wage norm binding regime (y < y_{low})', ...
       'BE Inverse-L (slack: flat, tight: steep)', ...
       'Location', 'northwest', 'FontSize', 10);
ylim([0 6]);
xlim([-5 6]);
grid on;
set(gca, 'FontSize', 11);

exportgraphics(fig2, 'fig_twist_as_curve_comparison.pdf', 'Resolution', 300);
fprintf('Figure 2 saved: fig_twist_as_curve_comparison.pdf\n');

%% 6. Summary diagnostics
% =========================================================================
fprintf('\n');
fprintf('=================================================================\n');
fprintf('  BE Twist Model — OccBin Scenario Summary\n');
fprintf('=================================================================\n');
fprintf('  Parameters: kappa_normal=%.4f, kappa_flat=%.4f, y_low=%.3f\n', ...
        kap_n, kap_f, y_low_val);
fprintf('  c_wnb = %.6f  (negative: continuity shift)\n', c_wnb_val);
fprintf('-----------------------------------------------------------------\n');
fprintf('  Scen N (small neg demand, eps_d=-0.003):\n');
fprintf('    y(1) = %.4f%%, pi(1) = %.4f pp (ann.)\n', ...
        results_normal_neg.piecewise(1,y_idx)*100, ...
        results_normal_neg.piecewise(1,pi_idx)*400);
fprintf('  Scen P (positive demand, eps_d=+0.03):\n');
fprintf('    y(1) = %.4f%%, pi(1) = %.4f pp (ann.)\n', ...
        results_pos.piecewise(1,y_idx)*100, ...
        results_pos.piecewise(1,pi_idx)*400);
fprintf('  Scen R (moderate recession, eps_d=-0.03):\n');
fprintf('    y(1)        = %.4f%% (piecewise), %.4f%% (linear)\n', ...
        results_recession.piecewise(1,y_idx)*100, ...
        results_recession.linear(1,y_idx)*100);
fprintf('    pi(1)       = %.4f pp piecewise, %.4f pp linear (ann.)\n', ...
        results_recession.piecewise(1,pi_idx)*400, ...
        results_recession.linear(1,pi_idx)*400);
fprintf('    Missing disinflation: %.4f pp (piecewise less negative)\n', ...
        (results_recession.piecewise(1,pi_idx) - results_recession.linear(1,pi_idx))*400);
fprintf('  Scen S (recession + supply, eps_d=-0.03, eps_s=+0.01):\n');
fprintf('    y(1) = %.4f%%, pi(1) piecewise = %.4f pp (ann.)\n', ...
        results_supply_recession.piecewise(1,y_idx)*100, ...
        results_supply_recession.piecewise(1,pi_idx)*400);
fprintf('    Supply shock add-on to pi (piecewise): %.4f pp\n', ...
        (results_supply_recession.piecewise(1,pi_idx) - results_recession.piecewise(1,pi_idx))*400);
fprintf('    Supply shock add-on to pi (linear):    %.4f pp\n', ...
        (results_supply_recession.linear(1,pi_idx) - results_recession.linear(1,pi_idx))*400);
fprintf('=================================================================\n');
fprintf('All simulations and plots completed.\n');
fprintf('Output PDFs: fig_twist_recession_comparison.pdf, fig_twist_as_curve_comparison.pdf\n');
