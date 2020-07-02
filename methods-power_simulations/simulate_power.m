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

sensors = ni2_sensors('type', 'eeg');
headmodel = ni2_headmodel('type', 'spherical', 'nshell', 3);

for i = 1:n_samples
    % basically, we're simulating a very rough estimate of more or less
    % plausible brain activity here that goes as follows (with some simplifications
    % so there aren't too many sources):
    %   superior olivary nuclei
    %       ->
    %   inferior colliculi
    %       ->
    %   medial geniculate nuclei
    %       ->
    %   thalamus
    %       ->
    %   Heschl's gyri
    %       ->
    %           right posterior hippocampus
    %           pars triangularis
    %               ->
    %                   right anterior & posterior hippocampus
    dippar = [
        % lSON
        ((-7 + randi([-1 1], 1)) * 1e-1) ((-29 + randi([-1 1], 1)) * 1e-1) ((-32 + randi([-1 1], 1)) * 1e-1);
        % rSON
        ((7 + randi([-1 1], 1)) * 1e-1) ((-29 + randi([-1 1], 1)) * 1e-1) ((-32 + randi([-1 1], 1)) * 1e-1);
        % lIC
        ((-5 + randi([-1 1], 1)) * 1e-1) ((-29 + randi([-1 1], 1)) * 1e-1) ((-22 + randi([-1 1], 1)) * 1e-1);
        % rIC
        ((5 + randi([-1 1], 1)) * 1e-1) ((-29 + randi([-1 1], 1)) * 1e-1) ((-22 + randi([-1 1], 1)) * 1e-1);
        % lMGN
        ((-6 + randi([-1 1], 1)) * 1e-1) ((-29 + randi([-1 1], 1)) * 1e-1) ((-9 + randi([-1 1], 1)) * 1e-1);
        % rMGN
        ((6 + randi([-1 1], 1)) * 1e-1) ((-29 + randi([-1 1], 1)) * 1e-1) ((-9 + randi([-1 1], 1)) * 1e-1);
        % lT
        ((-9 + randi([-1 1], 1)) * 1e-1) ((-20 + randi([-1 1], 1)) * 1e-1) ((9 + randi([-1 1], 1)) * 1e-1);
        % rT
        ((9 + randi([-1 1], 1)) * 1e-1) ((-20 + randi([-1 1], 1)) * 1e-1) ((9 + randi([-1 1], 1)) * 1e-1);
        % lHG
        ((-53 + randi([-1 1], 1)) * 1e-1) ((-5 + randi([-1 1], 1)) * 1e-1) ((8 + randi([-1 1], 1)) * 1e-1);
        % rHG
        ((53 + randi([-1 1], 1)) * 1e-1) ((-5 + randi([-1 1], 1)) * 1e-1) ((8 + randi([-1 1], 1)) * 1e-1);
        % lPT
        ((-56 + randi([-1 1], 1)) * 1e-1) ((18 + randi([-1 1], 1)) * 1e-1) ((8 + randi([-1 1], 1)) * 1e-1);
        % rPT
        ((56 + randi([-1 1], 1)) * 1e-1) ((18 + randi([-1 1], 1)) * 1e-1) ((8 + randi([-1 1], 1)) * 1e-1);
        % raHC (<- lPT)
        ((26 + randi([-2 2], 1)) * 1e-1) ((-13 + randi([-2 2], 1)) * 1e-1) ((-21 + randi([-2 2], 1)) * 1e-1);
        % rpHC (<- rHG & rPT)
        ((26 + randi([-2 2], 1)) * 1e-1) ((-28 + randi([-2 2], 1)) * 1e-1) ((-12 + randi([-2 2], 1)) * 1e-1);
    ];
    
    % create leadfield
    cfg = [];
    cfg.elec = sensors;
    cfg.headmodel = headmodel;
    cfg.grid.pos = dippar(:, 1:3);
    cfg.grid.inside = 1:size(dippar, 1);
    cfg.reducerank = 'no';
    lf = ft_prepare_leadfield(cfg);
    
    for k = 1:n_targets
        % condition 1
        % lSON
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [-c1_mod 0 0];
        leadfield1 = lf.leadfield{1} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 4, 1, [0.02 0.01]); % ~delta
        sensordata_c1(i, k, :, :) = leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rSON
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [c1_mod 0 0];
        leadfield1 = lf.leadfield{2} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 4, 1, [0.02 0.01]); % ~delta
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + (leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3));
        % lIC
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [-c1_mod 0 0];
        leadfield1 = lf.leadfield{3} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 3, 1, [0.04 0.04]); % ~delta
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rIC
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [c1_mod 0 0];
        leadfield1 = lf.leadfield{4} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 3, 1, [0.04 0.04]); % ~delta
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % lMGN
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [0 0 c1_mod];
        leadfield1 = lf.leadfield{5} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 12, 1, [0.1 0.08]); % ~alpha
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rMGN
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [0 0 c1_mod];
        leadfield1 = lf.leadfield{6} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 12, 1, [0.1 0.08]); % ~alpha
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % lT
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [-c1_mod 0 c1_mod];
        leadfield1 = lf.leadfield{7} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 13, 1, [0.14 0.08]); % ~alpha
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rT
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [c1_mod 0 c1_mod];
        leadfield1 = lf.leadfield{8} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 13, 1, [0.14 0.08]); % ~alpha
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % lHG
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [c1_mod c1_mod -c1_mod];
        leadfield1 = lf.leadfield{9} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 4, 1, [0.25 0.2]); % ~delta
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rHG
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [-c1_mod c1_mod -c1_mod];
        leadfield1 = lf.leadfield{10} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 4, 1, [0.25 0.2]); % ~delta
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % lPT
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [c1_mod -c1_mod -c1_mod];
        leadfield1 = lf.leadfield{11} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 25, 1, [0.25 0.2]); % ~gamma
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rPT
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [-c1_mod -c1_mod -c1_mod];
        leadfield1 = lf.leadfield{12} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 25, 1, [0.25 0.2]); % ~gamma
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % raHC (<- lPT)
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [0 0 c1_mod];
        leadfield1 = lf.leadfield{13} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 6, 1, [0.35 0.2]); % ~theta
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rpHC (<- rHG & rPT)
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [0 0 c1_mod];
        leadfield1 = lf.leadfield{14} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 6, 1, [0.35 0.2]); % ~theta
        sensordata_c1(i, k, :, :) = squeeze(sensordata_c1(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        
        
        % condition 2
        % lSON
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [-c1_mod 0 0];
        leadfield1 = lf.leadfield{1} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 4, 1, [0.02 0.01]); % ~delta
        sensordata_c2(i, k, :, :) = leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rSON
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [c1_mod 0 0];
        leadfield1 = lf.leadfield{2} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 4, 1, [0.02 0.01]); % ~delta
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % lIC
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [-c1_mod 0 0];
        leadfield1 = lf.leadfield{3} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 3, 1, [0.04 0.04]); % ~delta
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rIC
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [c1_mod 0 0];
        leadfield1 = lf.leadfield{4} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 3, 1, [0.04 0.04]); % ~delta
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % lMGN
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [0 0 c1_mod];
        leadfield1 = lf.leadfield{5} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 12, 1, [0.1 0.08]); % ~alpha
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rMGN
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [0 0 c1_mod];
        leadfield1 = lf.leadfield{6} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 12, 1, [0.1 0.08]); % ~alpha
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % lT
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [-c1_mod 0 c1_mod];
        leadfield1 = lf.leadfield{7} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 13, 1, [0.18 0.1]); % ~alpha
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rT
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [c1_mod 0 c1_mod];
        leadfield1 = lf.leadfield{8} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 13, 1, [0.18 0.1]); % ~alpha
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % lHG
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [c1_mod c1_mod -c1_mod];
        leadfield1 = lf.leadfield{9} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 4, 1, [0.25 0.2]); % ~delta
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rHG
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [-c1_mod c1_mod -c1_mod];
        leadfield1 = lf.leadfield{10} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 4, 1, [0.25 0.2]); % ~delta
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % lPT
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [c1_mod -c1_mod -c1_mod];
        leadfield1 = lf.leadfield{11} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 25, 1, [0.3 0.08]); % ~gamma
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rPT
        c1_mod = baseline + (baseline_var(randi([1 2], 1)) * rand());
        dipmom1 = [-c1_mod -c1_mod -c1_mod];
        leadfield1 = lf.leadfield{12} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 25, 1, [0.3 0.08]); % ~gamma
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % raHC (<- lPT)
        c2_mod = effect_size + (effect_var(randi([1 2], 1)) * rand());
        dipmom1 = [0 0 c2_mod];
        leadfield1 = lf.leadfield{13} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 6, 1, [0.35 0.2]); % ~theta
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
        % rpHC (<- rHG & rPT)
        c2_mod = effect_size + (effect_var(randi([1 2], 1)) * rand());
        dipmom1 = [0 0 c2_mod];
        leadfield1 = lf.leadfield{14} * dipmom1';
        [data, timecourse] = eeg_activation(1, 1000, 6, 1, [0.35 0.2]); % ~theta
        sensordata_c2(i, k, :, :) = squeeze(sensordata_c2(i, k, :, :)) + leadfield1 * data + (randn(size(leadfield1, 1), size(data, 2)) * 1e-3);
    end
end

% save our data to speed up the process in the future
save('/users/fabianschneider/desktop/university/master/dissertation/proposal/code/methods-power_simulations/mt_data.mat', 'timecourse', 'sensordata_c1', 'sensordata_c2');


%% some super basic ERP tests just to verify
clearvars; close all;
load('/users/fabianschneider/desktop/university/master/dissertation/proposal/code/methods-power_simulations/mt_data.mat');
sensors = ni2_sensors('type', 'eeg');

for part = 1:size(sensordata_c1, 1)
    new_data1(part, 1, :, :) = mean(sensordata_c1(part, :, :, :), 2);
    new_data3(part, 1, :, :) = mean(sensordata_c2(part, :, :, :), 2);
end

new_data1 = squeeze(new_data1);
new_data3 = squeeze(new_data3);
new_data2(:, :) = squeeze(mean(new_data1(:, :, :), 1)); % cond1
new_data4(:, :) = squeeze(mean(new_data3(:, :, :), 1)); % cond2

new_data5(:) = squeeze(mean(new_data2(:, :), 1)); % avg over channels
new_data6(:) = squeeze(mean(new_data4(:, :), 1)); % avg over channels

chandata1 = sqrt((new_data2(:,:) - mean(new_data2(:,:), 1)) .^ 2 / size(new_data2, 1)); % GMFP(t)
chandata2 = sqrt((new_data4(:,:) - mean(new_data4(:,:), 1)) .^ 2 / size(new_data4, 1)); % GMFP(t)
erpdata = squeeze(mean(chandata2, 1)) - squeeze(mean(chandata1, 1));
erpdata_all = chandata2 - chandata1;

ni2_topoplot(sensors, erpdata_all(:, 450)); colorbar;

ni2_topomovie(sensors, chandata1, timecourse);
ni2_topomovie(sensors, chandata2, timecourse);

ni2_topoplot(sensors, chandata1(:, 20)); colorbar; title("Superior olivary nucleus peak, t(20)"); % SON peak
ni2_topoplot(sensors, chandata1(:, 40)); colorbar; title("Inferior colliculus peak, t(40)"); % IC peak
ni2_topoplot(sensors, chandata1(:, 100)); colorbar; title("Medial geniculate nucleus peak, t(100)"); % MGN peak
ni2_topoplot(sensors, chandata1(:, 180)); colorbar; title("Thalamus peak, t(180)"); % T peak
ni2_topoplot(sensors, chandata1(:, 250)); colorbar; title("Heschl's peak, t(250)"); % HG peak
ni2_topoplot(sensors, chandata1(:, 300)); colorbar; title("Pars triangularis peak, t(300)"); % PT peak
ni2_topoplot(sensors, chandata1(:, 350)); colorbar; title("Hippocampus peak, t(350)"); % HC peak


figure;
plot(timecourse(300:600), erpdata(300:600), 'black-');
xlabel("Time (s)"); ylabel("ERP"); title("ERP plot");

figure;
subplot(1, 2, 1);
plot(timecourse(300:600), (chandata1(:, 300:600) .* 10e5 + repmat(linspace(1, size(chandata1, 1) .* 100, size(chandata1, 1)), 301, 1)'));
xlabel("Time (s)"); ylabel("Signal (mV)"); title("Condition 1 plot by electrode");
subplot(1, 2, 2);
plot(timecourse(300:600), (chandata2(:, 300:600) .* 10e5 + repmat(linspace(1, size(chandata2, 1) .* 100, size(chandata2, 1)), 301, 1)'));
xlabel("Time (s)"); ylabel("Signal (mV)"); title("Condition 2 plot by electrode");


%% permutation-based stats to get an estimate of our power
clearvars; close all;
load('/users/fabianschneider/desktop/university/master/dissertation/proposal/code/methods-power_simulations/mt_data.mat');
