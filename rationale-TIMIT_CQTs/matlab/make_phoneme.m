function make_phoneme(S, L, Fs, F1)
    p_t = 0:(1/Fs):(L-(1/Fs));
    p_A = 32767 .* exp(-0.0003 .* ones(1, length(p_t)));
    p_H = floor(Fs / F1);
    p_s = zeros(length(p_t), p_H);

    for i = 1:p_H
       p_s(:,i) = p_A .* sin(2 .* pi .* F1 .* i .* p_t);
    end

    p_s = mean(p_s, 2)';
    p_o = strcat('/users/fabianschneider/desktop/university/master/dissertation/proposal/code/rationale-TIMIT_CQTs/matlab/phonemes/', strcat(S, '.wav'));
    audiowrite(p_o, p_s, Fs);
end
