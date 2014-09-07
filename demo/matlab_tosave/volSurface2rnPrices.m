function [Q, vol, TT] = volSurface2rnPrices(rawVol,Ts,KK,dK,spot)
% take vol surface and turn into a matrix of risk neutral prices. 
% 
% USAGE:    [Q, vol, TT] = volSurface2rnPrices(rawVol,Ts,KK,dK,spot)
% 
% 

% more fully parametriz in the future
% m = 9;
% width = 0.1;

% interpolate at desired frequencies
TT = 90*(1:10)';        % quarterly frequency (1:(m+1))
[X1, Y1] = meshgrid(Ts,KK);
[X2, Y2] = meshgrid(TT,KK);
vol = interp2(X1,Y1,rawVol,X2,Y2);   % interpolated vol surface

% convert into transition matrix. Specify (,] intervals.
rr = -.4:.1:.4;
rrL = -.45:.1:.35;
rrR = -.35:.1:.45;

centers = spot*exp(rr);
lefts = spot*exp(rrL);
rights = spot*exp(rrR);
lefts(1) = 0;               % include tails
rights(end) = 100000;

% price matrix (risk neutral probabilities are prices)
Q = nan(length(centers),length(TT));
for i = 1:length(centers)
    leftIdx = find(KK > lefts(i),1,'first');
    rightIdx = find(KK <= rights(i),1,'last');
    
    for j = 1:length(TT)
        ff = vol(leftIdx:rightIdx,j);
        Q(i,j) = sum(ff)*dK;
    end
end

end
