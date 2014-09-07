function [KK, rnPmf, area] = price2rnd(call,K)
%   From call prices to risk neutral pmf. 
%   
% USAGE:    [KK, rnPmf] = price2Rnd(call,K)
% 

    dK = unique(diff(K));
    if length(dK) > 1
        error('grid not uniform.')
    end

    % take centered second order derivative
    rnPmf = nan(length(K)-2,1);
    for i = 2:(length(K)-1)
        rnPmf(i-1) = (call(i+1) -2*call(i) + call(i-1))/(dK^2);
    end

    area = sum(rnPmf)*dK;
    KK = K(2:end-1);

end