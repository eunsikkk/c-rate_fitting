clc; clear; close all;

%% Load COMSOL model
import com.comsol.model.*
import com.comsol.model.util.*

% Load model
model = mphload('C:\Users\ECHOI\Downloads\jr_roll_fix_eq_potential_anode_notation_fix.mph');

ModelUtil.showProgress(true);

%C-rates
C_rates = [1, 2, 4]; 

%% Load data
data_folder = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\RPT_data(Formation,OCV,DCIR,C-rate,GITT,RPT)\C_rate_data\C_rate2\data_result';
filename_data = "results_f.mat";
data_now = load(fullfile(data_folder, filename_data));

% C-rates struct
data_multi = struct('C_rate', {}, 'SOC', {}, 'V', {}); 
for i = 1:length(C_rates)
    C_rate = C_rates(i);
    idx = find([data_now.results_f.c_rate] == C_rate);
   
    data_multi(i).C_rate = C_rate;
    data_multi(i).SOC = data_now.results_f(idx).SOC_vec;
    data_multi(i).V = data_now.results_f(idx).V_vec;
end

%% Optimization

% initial parameter
para_0 = [0.1; 0.1; 0.1; 0.1]; 
lb = [0; 0; 0; 0]; % Lower bound
ub = [100; 100; 100; 100]; % Upper bound

% options
options = optimoptions('fmincon', ...
    'Display', 'iter', ...
    'MaxFunctionEvaluations', 200, ...
    'MaxIterations', 1000);

% Cost function handle
fhandle_cost = @(para) func_cost_multi(para, model, data_multi);

% optimization
para_hat = fmincon(fhandle_cost, para_0, [], [], [], [], lb, ub, [], options);

%% Run model

% fit_result
fit_result= struct('C_rate', {}, 'SOC_fit', {}, 'V_fit', {});

for i = 1:length(C_rates)
    C_rate = C_rates(i);
    model.param.set('C_rate', num2str(C_rate));
    
    % Set optimized parameter
    model.param.set('factor_n_am1_i0', sprintf('%.15g', para_hat(1)));
    model.param.set('factor_n_am1_Ds', sprintf('%.15g', para_hat(2)));
    model.param.set('factor_p_am1_i0', sprintf('%.15g', para_hat(3)));
    model.param.set('factor_p_am1_Ds', sprintf('%.15g', para_hat(4)));
    
    % Run model
    model.study('std1').run;
    
    % Get results
    SOC_model = mphglobal(model, 'SOC', 'dataset', 'dset1');
    V_model = mphglobal(model, 'E_cell', 'dataset', 'dset1');
    
    % struct 
    fit_result(i).C_rate = C_rate;
    fit_result(i).SOC_fit = SOC_model;
    fit_result(i).V_fit = V_model;
end

%% Plot results
figure;
hold on;
for i = 1:length(C_rates)
    % Plot experimental data
    plot(data_multi(i).SOC, data_multi(i).V, 'o', 'DisplayName', sprintf('Experimental Data C=%d', C_rates(i)));
    
    % Plot optimized model
    plot(fit_result(i).SOC_fit, fit_result(i).V_fit, '-', 'DisplayName', sprintf('Optimized Model C=%d', C_rates(i)));
end
xlabel('SOC');
ylabel('Voltage (V)');
legend;
hold off;

%% Multi c_rate cost function
function cost = func_cost_multi(para, model, data_multi)
    total_cost = 0;
    
    for i = 1:length(data_multi)
        C_rate = data_multi(i).C_rate;
        SOC_now = data_multi(i).SOC;
        V_now = data_multi(i).V;
        
        % Update parameters
        model.param.set('C_rate', num2str(C_rate));
        model.param.set('factor_n_am1_i0', sprintf('%.15g', para(1)));
        model.param.set('factor_n_am1_Ds', sprintf('%.15g', para(2)));
        model.param.set('factor_p_am1_i0', sprintf('%.15g', para(3)));
        model.param.set('factor_p_am1_Ds', sprintf('%.15g', para(4)));
        
       
        model.study('std1').run;
        
        % Get model output
        SOC_model = mphglobal(model, 'SOC', 'dataset', 'dset1');
        V_model = mphglobal(model, 'E_cell', 'dataset', 'dset1');
        
        % Interpolate model voltage
        V_model_interp = interp1(SOC_model, V_model, SOC_now, 'linear', 'extrap');
        
        % Calculate cost
        cost_i = sum((V_model_interp - V_now).^2);
        total_cost = total_cost + cost_i;
        
        fprintf('C_rate: %d, Parameters: %.15e %.15e %.15e %.15e, Cost_i: %.15e\n', ...
            C_rate, para(1), para(2), para(3), para(4), cost_i);
    end
    cost = total_cost;
end
