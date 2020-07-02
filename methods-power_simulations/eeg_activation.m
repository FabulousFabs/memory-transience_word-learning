function [d, t] = eeg_activation(L, Fs, f, A, p)
    s = 1 / Fs;
    t = 0:s:(L-s);
    d = zeros(size(t));
    
    for i = 1:size(p, 1)
        indxs = ceil((p(i, 1) - p(i, 2) / 2) * Fs);
        indxe = ceil((p(i, 1) + p(i, 2) / 2) * Fs) - 1;
        indxl = ((indxe - indxs) / Fs) - s;
        
        d_t = 0:s:indxl;
        d_s = A .* sin(2 * pi * f .* d_t);
        
        d(indxs:indxe-1) = hanning(length(d_s))' .* d_s;
    end
end