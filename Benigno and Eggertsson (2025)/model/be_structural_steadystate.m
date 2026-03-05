function [ys, params, check] = be_structural_steadystate(ys, exo, M_, options_)
% BE_STRUCTURAL_STEADYSTATE  External steady-state file for be_structural.mod
%
% The model is written entirely in log-deviations from steady state,
% so all endogenous variables are zero in steady state.
%
% This external file is provided because w_ex is a predetermined variable
% (appears with a lag), and Dynare sometimes benefits from an explicit
% steady-state file for models with state variables.

    check = 0;  % 0 = success

    % Number of endogenous variables
    n_endo = M_.endo_nbr;

    % All steady-state values are zero (model in log-deviations)
    ys = zeros(n_endo, 1);

    % Parameters are unchanged
    params = M_.params;

end
