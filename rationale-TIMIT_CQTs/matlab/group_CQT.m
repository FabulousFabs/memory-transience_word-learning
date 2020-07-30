%% TIMIT group CQT & clustering
% @description: Performs CQT to get the TFR of a group of sound snippets created from dig.py or dig_subject.py as
% well as k-means clustering.
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
ylabel("Frequency (Hz)");
xlabel("Time (ms)");
ylabel(c, "dB");
title("Mean constant-Q spectrogram");
saveas(gcf, strcat(out, "group_mean.png"));

%% k-means
X_k_clusters = 10;
X_k_m = reshape(X, [size(X, 1) * size(X, 2), size(X, 3)]);
X_k_m = log(abs(X_k_m) .^ 2);
[X_k_idx, X_k_C] = kmeans(X_k_m, X_k_clusters, 'MaxIter', 1000);
X_k_idx_shape = reshape(X_k_idx, [size(X, 1), size(X, 2)]);
X_k_idx_select = X_k_idx_shape(1:size(X_k_idx_shape, 1) / 2, :);
figure;
surf(t, f_e, X_k_idx_select, 'EdgeColor', 'None');
view(2);
axis([1 size(X_k_idx_select, 2) 0 max(f_e)]);
ylabel("Frequency (Hz)");
xlabel("Time (ms)");
title("Raw k-means cluster view");
saveas(gcf, strcat(out, "group_mean_cluster.png"));

X_k_m_transform = X_e + abs(min(min(X_e)));
X_k_m_transform = X_k_m_transform ./ max(max(X_k_m_transform));

for i = 1:X_k_clusters
    [X_k_cluster_r, X_k_cluster_c] = find(X_k_idx_select == i);
    X_k_cluster_E(i) = 0;
    for j = 1:length(X_k_cluster_r)
        X_k_cluster_E(i) = X_k_cluster_E(i) + X_k_m_transform(X_k_cluster_r(j), X_k_cluster_c(j));
    end
    X_k_cluster_E(i) = X_k_cluster_E(i) / length(X_k_cluster_r);
end
[X_k_cluster_B, X_k_cluster_I] = sort(X_k_cluster_E);
for i = 1:length(X_k_cluster_I)
    [X_k_cluster_r, X_k_cluster_c] = find(X_k_idx_select == X_k_cluster_I(i));
    for j = 1:length(X_k_cluster_r)
        X_k_idx_select(X_k_cluster_r(j), X_k_cluster_c(j)) = (i + 1e2);
    end
end
X_k_idx_select = X_k_idx_select - 1e2;

X_k_m_transform = X_k_m_transform + X_k_idx_select;
figure; hold on;
surf(t, f_e, X_k_m_transform, 'EdgeColor', 'None');
view(2);
axis([1 size(X_k_m_transform, 2) 0 max(f_e)]);
c_ti = linspace(1, max(max(X_k_m_transform)), X_k_clusters);
c_tl = arrayfun(@(x) ('Cluster ' + string(x)), 1:X_k_clusters);
c = colorbar('Ticks', c_ti, 'TickLabels', c_tl, 'Limits', [1 max(max(X_k_m_transform)) + 1]);
ylabel("Frequency (Hz)");
xlabel("Time (ms)");
ylabel(c, "K-Means Cluster with scaling normalised energy");
title("Clustered and scaled constant-Q spectrogram");
saveas(gcf, strcat(out, "group_mean_cluster_scaled.png"));

%% within group differences by pixel in cluster
clear X_k_cluster_spectral;

for i = 1:length(X_k_cluster_I)
    [X_k_cluster_r, X_k_cluster_c] = find(X_k_idx_select == i);
    X_k_cluster_spectral(i,:,:) = zeros(size(X_e, 1) * size(X_e, 2), size(X, 3));
    for j = 1:length(X_k_cluster_r)
        cluster_data = squeeze(X(X_k_cluster_r(j), X_k_cluster_c(j), :));
        cluster_data = log(abs(cluster_data) .^ 2);
        X_k_cluster_spectral(i, j, :) = cluster_data;
    end
end

X_k_cluster_spectral = reshape(X_k_cluster_spectral, [length(X_k_cluster_I), size(X_k_cluster_spectral, 2) * size(X_k_cluster_spectral, 3)]);

for i = 1:size(X_k_cluster_spectral, 1)
    test_data = nonzeros(X_k_cluster_spectral(i,:))';
    [X_k_cluster_ttest_h(i), X_k_cluster_ttest_p(i), X_k_cluster_ttest_ci(i,:), X_k_cluster_ttest_stats(i,:)] = ttest(test_data, 0, 'Alpha', (0.05 / size(X_k_cluster_spectral, 1)));
end

%% within group differences by clusters
clear X_k_cluster_spectral;

for i = 1:length(X_k_cluster_I)
    [X_k_cluster_r, X_k_cluster_c] = find(X_k_idx_select == i);
    X_k_cluster_spectral(i,:,:) = zeros(size(X_e, 1) * size(X_e, 2), size(X, 3));
    for j = 1:length(X_k_cluster_r)
        cluster_data = squeeze(X(X_k_cluster_r(j), X_k_cluster_c(j), :));
        cluster_data = log(abs(cluster_data) .^ 2);
        X_k_cluster_spectral(i, j, :) = cluster_data;
    end
end

for i = 1:size(X_k_cluster_spectral, 1)
    for j = 1:size(X_k_cluster_spectral, 3)
        X_k_cluster_spectral_m(i, j) = mean(nonzeros(X_k_cluster_spectral(i, :, j)));
    end
end

for i = 1:size(X_k_cluster_spectral, 1)
    [X_k_cluster_m_ttest_h(i), X_k_cluster_m_ttest_p(i), X_k_cluster_m_ttest_ci(i,:), X_k_cluster_m_ttest_stats(i,:)] = ttest(X_k_cluster_spectral_m(i, :), 0, 'Alpha', (0.05 / size(X_k_cluster_spectral, 1)));
end

%% time plots
da = X_k_cluster_spectral_m(:, 1:3);
%das(:, 1) = da(:, 1);
%das(:, 2) = da(:, 2);
%das(:, 3) = da(:, 3);
das(:, 1) = da(randperm(size(da, 1)), 1);
das(:, 2) = da(randperm(size(da, 1)), 2);
das(:, 3) = da(randperm(size(da, 1)), 3);

figure; hold on;
c = polyfit([1:size(das, 1)]', das(:, 1), 9);
y_est = polyval(c, 1:size(das, 1));
e1 = (sum((y_est' - das(:, 1)) .^ 2) + sum((y_est' - das(:, 2)) .^ 2) + sum((y_est' - das(:, 3)) .^ 2)) ./ size(das, 1);
e1t = (((y_est' - das(:, 1)) .^ 2) + ((y_est' - das(:, 2)) .^ 2) + ((y_est' - das(:, 3)) .^ 2)) ./ size(das, 1);
%plot(1:size(das, 1), y_est, 'black-');
errorbar(1:size(das, 1), y_est, e1t);
plot(1:size(das, 1), das(:, 1), 'r*');
plot(1:size(das, 1), das(:, 2), 'b*');
plot(1:size(das, 1), das(:, 3), 'm*');
xlabel("Time-frequency clusters");
ylabel("Spectral energy");
legend("Regression fit", "Speaker_1", "Speaker_2 (novel)", "Speaker_3 (novel)");
title("Overfit model (\epsilon = " + string(e1) + ")");
axis([1 10 -40 -5]);


figure; hold on;
c2 = polyfit([1:size(das, 1)]', das(:, 1), 1);
y_est2 = polyval(c2, 1:size(das, 1));
e2 = (sum((y_est2' - das(:, 1)) .^ 2) + sum((y_est2' - das(:, 2)) .^ 2) + sum((y_est2' - das(:, 3)) .^ 2)) ./ size(das, 1);
e2t = (((y_est2' - das(:, 1)) .^ 2) + ((y_est2' - das(:, 2)) .^ 2) + ((y_est2' - das(:, 3)) .^ 2)) ./ size(das, 1);
%plot(1:size(das, 1), y_est2, 'black-');
errorbar(1:size(das, 1), y_est2, e2t);
plot(1:size(das, 1), das(:, 1), 'r*');
plot(1:size(das, 1), das(:, 2), 'b*');
plot(1:size(das, 1), das(:, 3), 'm*');
xlabel("Time-frequency clusters");
ylabel("Spectral energy");
legend("Regression fit", "Speaker_1", "Speaker_2 (novel)", "Speaker_3 (novel)");
title("Simple model (\epsilon = " + string(e2) + ")");
axis([1 10 -40 -5]);

figure; hold on;
b = (1:size(das, 1))' ./ (1:size(das, 1))';
betas = b \ das(:, 1);
y_est3 = (b * betas)';
e3i = das(:, 1) - y_est3';
e3 = (sum((y_est3' - das(:, 1)) .^ 2) + sum((y_est3' - das(:, 2)) .^ 2) + sum((y_est3' - das(:, 3)) .^ 2)) ./ size(das, 1);
e3t = (((y_est3' - das(:, 1)) .^ 2) + ((y_est3' - das(:, 2)) .^ 2) + ((y_est3' - das(:, 3)) .^ 2)) ./ size(das, 1);
errorbar(1:size(das, 1), y_est3, e3t);
plot(1:size(das, 1), das(:, 1), 'r*');
plot(1:size(das, 1), das(:, 2), 'b*');
plot(1:size(das, 1), das(:, 3), 'm*');
xlabel("Time-frequency clusters");
ylabel("Spectral energy");
legend("Regression fit", "Speaker_1", "Speaker_2 (novel)", "Speaker_3 (novel)");
title("Simple GLM (\epsilon = " + string(e3) + ")");
axis([1 10 -40 -5]);
