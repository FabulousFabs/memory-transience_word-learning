%% first start
clearvars; close all;
addpath /Users/fabianschneider/Documents/MATLAB/ltfat
ltfatstart

%% go
[f,fs]=greasy;  % Get the test signal
[g,a,fc]=cqtfilters(fs,100,fs,2,length(f),'uniform');
c=filterbank(f,g,a);
plotfilterbank(c,a,fc,fs,90,'audtick');