clc; clear; close all;

%% Load COMSOL model
import com.comsol.model.*
import com.comsol.model.util.*

% Load model
model = mphload('C:\Users\ECHOI\Downloads\jr_roll_fix_eq_potential_anode_notation_epsilon_fix.mph');

ModelUtil.showProgress(true);

C_rate = 0.01;

model.param.set('C_rate', num2str(C_rate));

x0 = 0.0029 ;
x1 =  0.75;
y0 = 0.82;
y1 = 0.22;
n_delta = 5.112e-6 ;
thickness_pnratio = 1.00719;


model.param.set('n_am1_xmin', num2str(x0));
model.param.set('n_am1_xmax', num2str(x1));
model.param.set('p_am1_xmin', num2str(y1));
model.param.set('p_am1_xmax', num2str(y0));
model.param.set('n_delta', num2str(n_delta));
model.param.set('thickness_pnratio', num2str(thickness_pnratio));
% 모델 실행
model.study('std1').run;

% 초기 결과 저장
SOC_ocv1 = mphglobal(model, 'SOC', 'dataset', 'dset1');
OCV_ocv1 = mphglobal(model, 'OCV', 'dataset', 'dset1');


%% Load COMSOL model
import com.comsol.model.*
import com.comsol.model.util.*

% Load model
model = mphload('C:\Users\ECHOI\Downloads\jr_roll_fix_eq_potential_anode_notation_fix.mph');

ModelUtil.showProgress(true);

C_rate = 0.05;

model.param.set('C_rate', num2str(C_rate));

x0 = 0.0011 ;
x1 =  0.62;
y0 = 0.73;
y1 = 0.22;
n_delta = 6.437e-6 ;
thickness_pnratio = 0.98155;


model.param.set('n_am1_xmin', num2str(x0));
model.param.set('n_am1_xmax', num2str(x1));
model.param.set('p_am1_xmin', num2str(y1));
model.param.set('p_am1_xmax', num2str(y0));
model.param.set('n_delta', num2str(n_delta));
model.param.set('thickness_pnratio', num2str(thickness_pnratio));
% 모델 실행
model.study('std1').run;

% 초기 결과 저장
SOC_ocv2 = mphglobal(model, 'SOC', 'dataset', 'dset1');
OCV_ocv2 = mphglobal(model, 'OCV', 'dataset', 'dset1');

data_folder = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\OCV';
filename = 'FCC_(5)_OCV_C20.mat';
data_now = load(fullfile(data_folder,filename));

SOC_ocv1_data = data_now.OCV_golden.OCVchg(:,1);
OCV_ocv1_data = data_now.OCV_golden.OCVchg(:,2);

data_folder2 = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\OCV2';
filename2 = 'HNE_(6)_FCC_OCV2.mat';
data_now2 = load(fullfile(data_folder2,filename2));

SOC_ocv2_data = data_now2.OCV_golden.OCVchg(:,1);
OCV_ocv2_data = data_now2.OCV_golden.OCVchg(:,2);

figure(1)
plot(SOC_ocv1,OCV_ocv1,'DisplayName','OCV1')
hold on
plot(SOC_ocv2,OCV_ocv2,'DisplayName','OCV2')
plot(SOC_ocv1_data,OCV_ocv1_data,'DisplayName','OCV1Data')
plot(SOC_ocv2_data,OCV_ocv2_data,'DisplayName','OCV2Data')

xlim([0 1])
hold off
xlabel('SOC');
ylabel('OCV');
legend;
