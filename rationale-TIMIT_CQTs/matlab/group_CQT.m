%% TIMIT group CQT
% @description: Performs CQT to get the TFR of a group of sound snippets
% previously created from our dig.py
% @author: Fabian Schneider <f.schneider@donders.ru.nl>

clearvars; close all;

%% settings
targets = "/users/fabianschneider/desktop/university/master/dissertation/proposal/code/rationale-TIMIT_CQTs/data/converted/"; % the folder with all our converted data we want to include in the TFR
out = "/users/fabianschneider/desktop/university/master/dissertation/proposal/code/rationale-TIMIT_CQTs/matlab/export/";
screen_x = 2560;
screen_y = 1600;

%% find
files = dir(strcat(targets, '*.wav'));

%% find shortest
len_min = 1e9;
for file = files'
    s = audioread(strcat(targets, file.name));
    if length(s) < len_min
        len_min = length(s);
    end
end

%% matrix setup
M = zeros(len_min, length(files));
e = 1;
Fs = 0;
for file = files'
    [s, fs] = audioread(strcat(targets, file.name));
    Fs = fs;
    % resample signal so we avoid the issue of sampling rate
    if length(s) > len_min
        RS = (len_min / length(s)) * Fs;
        [P,Q] = rat(RS/Fs);
        rs = resample(s, P, Q);
        M(:,e) = rs(1:len_min);
    else
        M(1:length(s),e) = s;
    end
    e = e + 1;
end

%% CQTs
[test_cqt, f] = cqt(M(:,1), 'SamplingFrequency', Fs);
t = 1:size(test_cqt, 2);
dimensions_mn = size(test_cqt);
X = zeros(dimensions_mn(1), dimensions_mn(2), size(M, 2));

for i = 1:size(M, 2)
    X(:,:,i) = cqt(M(:,i), 'SamplingFrequency', Fs);
end

X_m = abs(mean(X, 3));
X_d = X_m(1:(size(X_m, 1) / 2),:);
X_d(2:size(X_d, 1),:) = 2 .* X_d(2:size(X_d, 1),:);
X_e = log(X_d .^ 2);
f_e = f(1:size(X_e, 1));

%% group mean
figure;
surf(t, f_e, X_e, 'EdgeColor', 'None');
view(2);
axis([1 size(X_e, 2) 0 max(f_e)]);
c = colorbar;
ylabel("Frequency (kHz)");
xlabel("Time (ms)");
ylabel(c, "dB");
title("Mean constant-Q spectrogram");
saveas(gcf, strcat(out, "group_mean.png"));

%% group mean PCA
X_e_m = mean(X_e, 2);
X_e_dm = X_e - X_e_m;
[PCA_M_coeff, PCA_M_score, PCA_M_latent] = pca(X_e_dm);
PCA_M_data = PCA_M_score(:,1) * PCA_M_coeff(:,1)' + X_e_m;
figure;
surf(t, f_e, PCA_M_data, 'EdgeColor', 'None');
view(2);
axis([1 size(PCA_M_data, 2) 0 max(f_e)]);
c = colorbar;
ylabel("Frequency (kHz)");
xlabel("Time (ms)");
ylabel(c, "dB");
title("PC Mean constant-Q spectrogram");
