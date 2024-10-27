clear; clc; close all;


%% Interface

id_cfa =3;
np =-1; % 1 for CHC and FC, -1 for AHC
result_save_folder = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\OCV\es_ex_1C\OCV2';

if id_cfa == 1 % cathode data_folder
    data_folder = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\RPT_data(Formation,OCV,DCIR,C-rate,GITT,RPT)\C_rate_data\C_rate2\HNE_CHC_(4)_Crate2';
    OCV_fullpath = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\OCV2\HNE_(4)_CHC_OCV2.mat';
elseif id_cfa == 2 % FC data_folder
    data_folder = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\RPT_data(Formation,OCV,DCIR,C-rate,GITT,RPT)\C_rate_data\C_rate2\HNE_FCC_(6)_Crate2';
    OCV_fullpath = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\OCV2\HNE_(6)_FCC_OCV2.mat';
elseif id_cfa == 3 % anode
    data_folder = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\RPT_data(Formation,OCV,DCIR,C-rate,GITT,RPT)\C_rate_data\C_rate2\HNE_AHC_(4)_Crate2';
    OCV_fullpath = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\OCV2\HNE_(5)_AHC_OCV2.mat';
end



% test parameters
    % capacity
    I_1C = 4.77e-3; % [A]
    % tested c-rates
    crate_chg_vec = [0.1, 0.5, 1, 2, 4, 6];
    crate_dis_vec = -crate_chg_vec;


%% Engine

% load OCV
load(OCV_fullpath) % variables: OCV_all, OCV_golden

% C-rate test filees
files = dir([data_folder filesep '*.mat']);

%% struct
if id_cfa == 1
    results_c = struct('c_rate', {}, 'y_vec', {}, 'V_vec', {},'cumdQ_vec',{});
elseif id_cfa ==2 
    results_f = struct('c_rate', {}, 'SOC_vec', {}, 'V_vec', {},'cumdQ_vec',{});
elseif id_cfa ==3
    results_a = struct('c_rate', {}, 'x_vec', {}, 'V_vec', {},'cumdQ_vec',{});
end
    

%%

for i = 1
    fullpath_i = [data_folder filesep files(i).name];
    load(fullpath_i) % variable: data

    step_crate_chg = zeros(size(crate_chg_vec)); n = 1; 
    step_crate_dis = zeros(size(crate_dis_vec)); m = 1;
    for j = 1:length(data)
        % calculate the average current
            % ** this will be the selection criteria 
        data(j).Iavg = mean(data(j).I);

        % calculate step capacity (absolute)
        if length(data(j).t) > 1
            data(j).dQ = abs(trapz(data(j).t,data(j).I))/3600; % [Ah]
            data(j).cumdQ = abs(cumtrapz(data(j).t,data(j).I))/3600; %[Ah]
        else
            data(j).dQ = 0;
            data(j).cumdQ = 0;
        end
        


        % marking C-rate tests
        
        nth_chg = find(abs(crate_chg_vec - data(j).Iavg/I_1C) < 0.0011);
        nth_dis = find(abs(crate_dis_vec - data(j).Iavg/I_1C) < 0.0011);

        if ~isempty(nth_chg) && np*j < np*length(data)/2
            data(j).mark = nth_chg; % charging mark: 1, 2 ,3,..
            step_crate_chg(n) = j;
            n = n+1;
        elseif  ~isempty(nth_dis) && np*j > np*length(data)/2
            data(j).mark = -nth_dis; % dicharging mark: -1, -2, -3,...
            step_crate_dis(m) = j;
            m = m+1;
        else
            data(j).mark = 0;
        end
 
        if id_cfa == 3
        end

    end


    clear n m



    %% Plot Charging

    % if np < 0 % anode
    % step_crate_chg = [3,7,11,15,19,23];
    % step_crate_dis = [27,31,35,39,43,47];
    % end

    % color map
    c_mat = turbo(length(step_crate_dis)+1);

    % plot OCV
    Q_ocv = mean([OCV_all.Qchg]);
    figure(1)
    hold on; box on
    plot(OCV_golden.OCVchg(:,1),OCV_golden.OCVchg(:,2),'Color',c_mat(1,:))
    

    % plot only C-rate tests
    %% for n
    for n = 1:length(step_crate_chg)
        j_n = step_crate_chg(n);
       
        
        % calculate soc
        [x_uniq_chg,ind_uniq_chg] = unique(OCV_golden.OCVchg(:,2));
        y_uniq_chg = OCV_golden.OCVchg(ind_uniq_chg',1);
        
        if id_cfa ==1
        data(j_n).y={};
        y0 = interp1(x_uniq_chg,y_uniq_chg,data(j_n-1).V(end),'linear','extrap');
        elseif id_cfa==2
        soc0 = interp1(x_uniq_chg,y_uniq_chg,data(j_n-1).V(end),'linear','extrap');
        elseif id_cfa==3
        data(j_n).x={};
        x0 = interp1(x_uniq_chg,y_uniq_chg,data(j_n-1).V(end),'linear','extrap');
        end    
    end
%% for m
     for m = 1:length(step_crate_dis)
        j_m = step_crate_dis(m);

        % calculate soc
        [x_uniq_dis,ind_uniq_dis] = unique(OCV_golden.OCVdis(:,2));
        y_uniq_dis = OCV_golden.OCVdis(ind_uniq_dis',1);
       if id_cfa ==1
           data(j_m).y={};
        y1 = interp1(x_uniq_chg,y_uniq_chg,data(j_m-1).V(end),'linear','extrap');
        elseif id_cfa==2
        soc1 = interp1(x_uniq_chg,y_uniq_chg,data(j_m-1).V(end),'linear','extrap');
        elseif id_cfa==3
             data(j_m).x={};
        x1 = interp1(x_uniq_chg,y_uniq_chg,data(j_m-1).V(end),'linear','extrap');
       end
        
     end

%% for stoic
     if id_cfa ==1
         data(j_n).soc = data(j_n).y;
         data(j_m).soc = data(j_m).y;
     elseif id_cfa ==3
         data(j_n).soc = data(j_n).x;
         data(j_m).soc = data(j_m).x;
     end
%% for plot
    for n = 1:length(step_crate_chg)
        j_n = step_crate_chg(n);
        if id_cfa ==1 
            data(j_n).y = y0-(y0-y1)*data(j_n).cumdQ/Q_ocv;
        elseif id_cfa ==2 
            data(j_n).soc = soc0 + data(j_n).cumdQ/Q_ocv;
        elseif id_cfa ==3
            data(j_n).x= x0+(x1-x0)*data(j_n).cumdQ/Q_ocv;
        end
    
        % plot

        if id_cfa ==1 
        plot(data(j_n).y,(data(j_n).V),'Color',c_mat(n+1,:))
        elseif id_cfa ==2
        plot(data(j_n).soc,(data(j_n).V),'Color',c_mat(n+1,:))
        xlim([0,1])
        elseif id_cfa ==3
        plot(data(j_n).x,(data(j_n).V),'Color',c_mat(n+1,:))
        end

         if id_cfa ==1
        results_c(end+1).c_rate = crate_chg_vec(n);
        results_c(end).y_vec = data(j_n).y;
        results_c(end).V_vec = data(j_n).V;
        results_c(end).cumdQ_vec = data(j_n).cumdQ;
        elseif id_cfa ==2
        results_f(end+1).c_rate = crate_chg_vec(n);
        results_f(end).SOC_vec = data(j_n).soc;
        results_f(end).V_vec = data(j_n).V;
        results_f(end).cumdQ_vec = data(j_n).cumdQ;
        elseif id_cfa ==3
        results_a(end+1).c_rate = crate_chg_vec(n);
        results_a(end).x_vec = data(j_n).x;
        results_a(end).V_vec = data(j_n).V;
        results_a(end).cumdQ_vec = data(j_n).cumdQ;
        end
    end
    
    if id_cfa == 1 || id_cfa == 2
    legend({'C/100','C/10','C/2','1C','2C','4C','6C'},'Location','southwest')
    elseif id_cfa == 3 
    legend({'C/100','C/10','C/2','1C','2C','4C','6C'},'Location','northeast')
    end
    
    
    %anode struct savefile
    if id_cfa == 3
    save(fullfile(result_save_folder, 'results_a.mat'), 'results_a');
    end

    % if np <0
    %     return
    % end
%% Plot Discharging

    figure(2)
    hold on; box on
    plot(OCV_golden.OCVdis(:,1),OCV_golden.OCVdis(:,2),'Color',c_mat(1,:))


    for m = 1:length(step_crate_dis)
        j_m = step_crate_dis(m);

        % calculate soc1
        if id_cfa == 1 % Cathode
          data(j_m).y = y1 +(y0-y1)*data(j_m).cumdQ/Q_ocv;
        elseif id_cfa == 2 %Fullcell
       [x_uniq_dis,ind_uniq_dis] = unique(OCV_golden.OCVdis(:,2));
        y_uniq_dis = OCV_golden.OCVdis(ind_uniq_dis',1);
        soc1 = interp1(x_uniq_dis,y_uniq_dis,data(j_m-1).V(end),'linear','extrap');
          data(j_m).soc = soc1-data(j_m).cumdQ/Q_ocv;
        elseif id_cfa == 3 %anode
          % data(j_m).soc = 1-data(j_m).cumdQ/Q_ocv;
          data(j_m).x = x1 +(x0-x1)*data(j_m).cumdQ/Q_ocv;

        end

        %plot
        if id_cfa ==1 
        plot(data(j_m).y,data(j_m).V,'color',c_mat(m+1,:))
        elseif id_cfa ==2
        xlim([0,1])
        plot(data(j_m).soc,data(j_m).V,'color',c_mat(m+1,:))
        elseif id_cfa ==3
        plot(data(j_m).x,data(j_m).V,'color',c_mat(m+1,:))
        end

       if id_cfa ==1
       results_c(end+1).c_rate = crate_dis_vec(m);
       results_c(end).y_vec = data(j_m).y;
       results_c(end).V_vec = data(j_m).V;
       results_c(end).cumdQ_vec = data(j_m).cumdQ;
      elseif id_cfa ==2
       results_f(end+1).c_rate = crate_dis_vec(m);
       results_f(end).SOC_vec = data(j_m).soc;
       results_f(end).V_vec = data(j_m).V;
       results_f(end).cumdQ_vec = data(j_m).cumdQ;
      elseif id_cfa ==3 
       results_a(end+1).c_rate = crate_dis_vec(m);
       results_a(end).x_vec = data(j_m).x;
       results_a(end).V_vec = data(j_m).V;
       results_a(end).cumdQ_vec = data(j_m).cumdQ;
      end

    end


    legend({'C/100','C/10','C/2','1C','2C','4C','6C'},'Location','northwest')


end

if id_cfa == 1
    save(fullfile(result_save_folder, 'results_c.mat'), 'results_c');
elseif id_cfa == 2
    save(fullfile(result_save_folder, 'results_f.mat'), 'results_f');
end


