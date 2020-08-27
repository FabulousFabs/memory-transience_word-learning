using Plots
using DSP
using FFTW

include("CQT.jl");

Fs = 16000;
fs = 1 / Fs;
fm = Fs / 2;
t = 0:fs:(1-fs);
tf = 15;
b = 2.2;

F, B, N = CQT_freq(;f0=tf,b=b);

filterbank = zeros(length(F), Fs);

for i = 1:length(F)
    Hs_n = round(Int, (2 * F[i]) + (B[i] / 2));
    Hs_p = fm - Hs_n;
    Hs_p = Hs_p > 0 ? Hs_p : 0;
    Hs_i = hanning(Hs_n; padding=convert(Int, Hs_p));
    Hs_n = Hs_n > fm ? convert(Int, fm) : Hs_n;
    Hs_i = length(Hs_i) > fm ? Hs_i[1:convert(Int, fm)] : Hs_i;
    #Hs_x = [0; reverse(Hs_i, dims=1); Hs_i];
    Hs_x = [Hs_i; reverse(Hs_i, dims=1)];
    #Hs_x = [Hs_i; Hs_i];
    filterbank[i:i, 1:length(Hs_x)] = Hs_x;
end

display(plot(1:fm, filterbank[:,1:convert(Int, fm)]', legend=false, title="Positive frequency responses"));

impulses = zeros(length(F), Fs) .+ 0im;

for i = 1:length(F)
    Y = ifft(filterbank[i,:]) |> fftshift;
    y = Y .* conj(Y);
    impulses[i,1:length(Y)] = y;
    #Y = ifft(filterbank[i,:]);
    #impulses[i,1:length(Y)] = Y;
end

impulses[:,:] = impulses[:,:] ./ maximum(abs.(impulses));

impulse_zoom = zeros(length(F), maximum(N)) .+ 0im;
z_b = round(Int, (Fs / 2) - (maximum(N) / 2));
z_e = z_b + maximum(N);
impulse_zoom = impulses[:, z_b:(z_e-1)];

## real part
#p_F_r = repeat(1:length(F), 1, maximum(N))';
#p_N_r = repeat((1:maximum(N)) ./ Fs, 1, length(F));
#p_X_r = real.(impulse_zoom[:,:])';
#display(plot(p_F_r, p_N_r, p_X_r, legend=false, title="Real impulse responses"));

## imaginary part
#p_F_i = repeat(1:length(F), 1, maximum(N))';
#p_N_i = repeat((1:maximum(N)) ./ Fs, 1, length(F));
#p_X_i = imag.(impulse_zoom[:,:])';
#display(plot(p_F_i, p_N_i, p_X_i, legend=false, title="Imaginary impulse responses"));

# absolute plot
p_F_a = repeat(1:length(F), 1, maximum(N))';
p_N_a = repeat((1:maximum(N)) ./ Fs, 1, length(F));
p_X_a = abs.(impulse_zoom[:,:])';
display(plot(p_F_a, p_N_a, p_X_a, legend=false, title="Absolute impulse responses"));
