function [K, f, originalIdx] = interpolateSmile(K,sigma,spot,forward,T,dK,minK,maxK,plotCompletion)
% 
%   USAGE:  [K, f, originalIdx] = interpolateSmile(K,sigma,spot,forward,T,dK,minK,maxK,plotCompletion)
%   
%   INPUTS: 
%       T - in years
%       dK - desired grid step
% 
%   OUTPUTS:
%       K - strikes
%       f - risk neutral pdf
%       originalIdx - vector of zeros and ones, with one indicating the
%           data comes from true options. 
% 

% 1) vol -> call prices
[K, call] = vol2price(K,sigma,spot,forward,T,dK);

% 2) prices to RND (middle)
[K, rnPmf, area] = price2rnd(call,K);

% 3) Complete tails
if area < 0.995 && (min(K) >= minK && max(K) <= maxK)
    [K, f, originalIdx] = completeTailsV2(rnPmf,K,plotCompletion,minK,maxK);
elseif area > 1.01
    error(['area = ' num2str(area)])
else
    f = rnPmf;
    originalIdx = ones(size(f));
end



