clc; clear; close all;
%% Load COMSOL model
import com.comsol.model.*
import com.comsol.model.util.*

% Load model
%model = mphload("G:\Shared Drive\Battery Software Lab\0_Group Meeting\Individual_MeetingMaterials\최은식\2024\COMSOL\echem\c20.mph");
%model = mphload("C:\Users\dsdsd\downloads\c20 (1).mph");
%model = mphload("C:\Users\dsdsd\Downloads\jr_roll_fix_eq_potential_anode_notation_fix.mph");

model = mphload('C:\Users\ECHOI\Downloads\jr_roll_fix_eq_potential_anode_notation_fix.mph');

ModelUtil.showProgress(true);

C_rate = 2; 

%% Load data
%data_folder = 'G:\Shared Drive\BSL-Data\Processed_data\Hyundai_dataset\OCV\es_ex_1C';
data_folder_OCV1 = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\RPT_data(Formation,OCV,DCIR,C-rate,GITT,RPT)\C_rate_data\C_rate2\data_result'; 
filename_data_OCV1 = "results_f.mat";
data_now_OCV1 = load(fullfile(data_folder_OCV1, filename_data_OCV1));

data_folder_OCV2 = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\OCV\es_ex_1C\OCV2'; 
filename_data_OCV2 = "results_f.mat";
data_now_OCV2 = load(fullfile(data_folder_OCV2, filename_data_OCV2));

% SOC_now = data_now.results_f(3).SOC_vec;
% V_now = data_now.results_f(3).V_vec; % 3rd item (C-rate == 1)

c_rate_vec1 = [data_now_OCV1.results_f.c_rate];

idx1 = find(c_rate_vec1 == C_rate ); % use index to find c_rate

c_rate_vec2 = [data_now_OCV2.results_f.c_rate];

idx2 = find(c_rate_vec2 == C_rate ); % use index to find c_rate

SOC_now_OCV1 = data_now_OCV1.results_f(idx1).SOC_vec;
V_now_OCV1 = data_now_OCV1.results_f(idx1).V_vec;

SOC_now_OCV2 = data_now_OCV2.results_f(idx2).SOC_vec;
V_now_OCV2 = data_now_OCV2.results_f(idx2).V_vec;


%% Run initial model

model.param.set('C_rate', num2str(C_rate));

% Set initial parameter
para_0 = [0.1;0.1;0.1;0.1]; 
lb = [0; 0; 0; 0]; % Lower bound
ub = [100; 100; 100; 100]; % Upper bound

% Apply initial parameters
model.param.set('factor_n_am1_i0', num2str(para_0(1)));
model.param.set('factor_n_am1_Ds', num2str(para_0(2)));
model.param.set('factor_p_am1_i0', num2str(para_0(3)));
model.param.set('factor_p_am1_Ds', num2str(para_0(4)));

% Run
model.study('std1').run;

% Save results
SOC_init = mphglobal(model, 'SOC', 'dataset', 'dset1');
V_init = mphglobal(model, 'E_cell', 'dataset', 'dset1');

%% optimization 

options = optimoptions('fmincon', ...
    'Display', 'iter', ...
    'MaxFunctionEvaluations', 300);

% cost function
fhandle_cost = @(para) func_cost(para, model, SOC_now, V_now);

% Run optimization
para_hat = fmincon(fhandle_cost, para_0, [], [], [], [], lb, ub, [], options);


%% Run model with optimized parameters

model.param.set('factor_n_am1_i0', sprintf('%.15g', para_hat(1)));
model.param.set('factor_n_am1_Ds', sprintf('%.15g', para_hat(2)));
model.param.set('factor_p_am1_i0', sprintf('%.15g', para_hat(3)));
model.param.set('factor_p_am1_Ds', sprintf('%.15g', para_hat(4)));


model.study('std1').run;

% optimized model results
SOC_fit = mphglobal(model, 'SOC', 'dataset', 'dset1');
V_fit = mphglobal(model, 'E_cell', 'dataset', 'dset1');

%% Plot results
figure;
plot(SOC_now, V_now, 'o', 'DisplayName', 'Experimental Data');
hold on;
plot(SOC_fit, V_fit, '-', 'DisplayName', 'Optimized Model');
plot(SOC_init, V_init, '--', 'DisplayName', 'Initial Model');
xlabel('SOC');
ylabel('Voltage (V)');
legend;
title('2C fitting');

%% Define Function
function cost = func_cost(para, model, SOC_now, V_now)
    % Update model parameters
    model.param.set('factor_n_am1_i0', sprintf('%.15g', para(1)));
    model.param.set('factor_n_am1_Ds', sprintf('%.15g', para(2)));
    model.param.set('factor_p_am1_i0', sprintf('%.15g', para(3)));
    model.param.set('factor_p_am1_Ds', sprintf('%.15g', para(4)));
    
    
    model.study('std1').run;

    % Get model output
    SOC_model = mphglobal(model, 'SOC', 'dataset', 'dset1');
    V_model = mphglobal(model, 'E_cell', 'dataset', 'dset1');

   
    V_model_interp = interp1(SOC_model, V_model, SOC_now, 'linear', 'extrap');

    % Calculate cost function
    cost = sum((V_model_interp - V_now).^2);

    fprintf('Parameters: %e %e %e %e, Cost: %e\n', ...
         para(1), para(2), para(3), para(4), cost);
end
