# dummy test of CQT functions

using Plots
using DSP
using FFTW

include("CQT.jl");

Fs = 10;
fs = 1 / Fs;
fm = Fs / 2;
T = 1;
t = 0:fs:(T-fs);
tf = 20;
b = 2.2;

#s = ones(length(t));
#X, F, B, N = CQT_spectrogram(s; b = b, l = 32, s = 16, fs = Fs);
#plot_spectrogram(abs.(X), F, 1e0, "Spectrogram test"); # should convert to dB or spectral energy or something but doesnt matter right now

# dummy tests
s = sin.(2 * pi * 4 .* t);
fft_F = fft(s);
fft_Y = ifft(fft_F);
