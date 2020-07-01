clearvars; close all;

%% start-up FT & NI2 (for first run only)
addpath /Users/fabianschneider/Documents/MATLAB/fieldtrip
addpath /Users/fabianschneider/Documents/MATLAB/ni2
ft_defaults

%% simulate some EEG data with underlying left hippocampal source
clearvars; close all;

n_samples = 20; % population size
n_targets = 20; % number of targets per condition
baseline = 1; % condition1 amplitude
baseline_var = [-0.15 0.15]; % variation of condition1 amplitude
effect_size = 1.5; % condition2 amplitude
effect_var = [-0.25 0.25]; % variation of condition2 amplitude

% i'm using ni2 functions for convenience here because they do pretty much
% exactly what i need so I can avoid more direct ft_* calls (and some
% general refactoring), thanks to Jan-Mathijs Schoffelen

[data, timecourse] = ni2_activation('frequency', 5.5); % theta is were we expect the activity differences to be apparent
sensors = ni2_sensors('type', 'eeg');
headmodel = ni2_headmodel('type', 'spherical', 'nshell', 3);

for i = 1:n_samples
    % I initially localised the left hippocampus in a T1 of my brain but that isn't
    % terribly generalisable so we're now using MNI coordinates for the
    % left HC (obtained from https://journals.plos.org/plosone/article/file?type=supplementary&id=info:doi/10.1371/journal.pone.0019985.s004)
    % and adding some +-3mm random variation per participant
    %   e.g., x = -20 (+-3), y = -30 (+-3), z = -8 (+-3)
    dippar_x = (-20 + randi([-3 3], 1)) * 1e-1;
    dippar_y = (-30 + randi([-3 3], 1)) * 1e-1;
    dippar_z = (-8 + randi([-3 3], 1)) * 1e-1;
    dippar = [dippar_x dippar_y dippar_z];
    
    % create leadfield
    cfg = [];
    cfg.elec = sensors;
    cfg.headmodel = headmodel;
    cfg.grid.pos = dippar(:, 1:3);
    cfg.grid.inside = 1:1;
    cfg.reducerank = 'no';
    lf = ft_prepare_leadfield(cfg);
    
    for k = 1:n_targets
        % condition 1
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [c1_mod 0 c1_mod];
        leadfield1 = lf.leadfield{1} * dipmom1';
        sensordata_c1(i, k, :, :) = leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        
        % condition 2
        c2_mod = effect_size + (effect_var(randi([1 2], 1)) * rand());
        dipmom2 = [c2_mod 0 c2_mod];
        leadfield2 = lf.leadfield{1} * dipmom2';
        sensordata_c2(i, k, :, :) = leadfield2 * data + (randn(size(leadfield2, 1), size(data, 2)) * 1e-3);
    end
end

% save our data to speed up the process in the future
save('/users/fabianschneider/desktop/university/master/dissertation/proposal/code/methods-power_simulations/mt_data.mat', 'timecourse', 'sensordata_c1', 'sensordata_c2');


%% some super basic ERP tests just to verify
clearvars; close all;
load('/users/fabianschneider/desktop/university/master/dissertation/proposal/code/methods-power_simulations/mt_data.mat');

for part = 1:size(sensordata_c1, 1)
    new_data1(part, 1, :, :) = mean(sensordata_c1(part, :, :, :), 2);
    new_data3(part, 1, :, :) = mean(sensordata_c2(part, :, :, :), 2);
end
new_data1 = squeeze(new_data1);
new_data3 = squeeze(new_data3);
new_data2(:, :) = squeeze(mean(new_data1(:, :, :), 1)); % cond1
new_data4(:, :) = squeeze(mean(new_data3(:, :, :), 1)); % cond2
ni2_topoplot(sensors, new_data4(:, 500) - new_data2(:, 500)); colorbar;

new_data5(:) = squeeze(mean(new_data2(:, :), 1)); % avg over channels
new_data6(:) = squeeze(mean(new_data4(:, :), 1)); % avg over channels

figure; hold on;
plot(timecourse(300:600), new_data5(300:600), 'r-');
plot(timecourse(300:600), new_data6(300:600), 'b-');

%% permutation-based stats to get an estimate of our power
clearvars; close all;
load('/users/fabianschneider/desktop/university/master/dissertation/proposal/code/methods-power_simulations/mt_data.mat');
