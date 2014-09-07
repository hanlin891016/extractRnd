function [KK, call] = vol2price(K,sigma,spot,forward,T,dK)
% transform implied volatility numbers to call and put prices.
%
% USAGE: [call, put, sigma] = vol2price(K,sigma,spot,forward,T,dK)
%

order = 5;  % order of spline

div = - log(forward/spot)/T;  % implied dividend when risk free rate is 0.

% fourth order spline in vol space
KK = (min(K):dK:max(K))';
pieces = floor(length(KK)/order);  % piece-wise fourth order spline
pp = splinefit(K,sigma,pieces,order+1);
sigma = ppval(pp,KK);

call = nan(size(KK));
put = nan(size(KK));
for i = 1:length(KK)
    [call(i), put(i)] = blsprice(spot, KK(i), 0, T, sigma(i), div);
end

end