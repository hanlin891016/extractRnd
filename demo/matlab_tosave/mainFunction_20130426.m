% NOTES

% 1) think of ways to make transporting inputs and global parameters easier. (struct)

%% 1) Process inputs

clear

addpath('/Users/jl52/matlabLibraries/')
addpath('/Users/jl52/matlabLibraries/QCTSLib/')

pricingDate = 20130419;

% vol surface
V = csv2struct_J('volsurface_20130419.csv',[1 1 1 1 1]);
% V = dlm2struct('volsurface_20130419.csv',',',[1 1 1 1 1]);
V.T = yyyymmdd2date(V.yyyymmdd) - yyyymmdd2date(pricingDate);
V = renamefield(V,'Strike','K');
V = renamefield(V,'impliedVol','sigma');
V = rmfield(V,{'yyyymmdd','Spot','Dividend'});

% futures
F = csv2struct_J('futures_20130419.csv',[0 1 1]);
% F = dlm2struct('futures_20130419.csv',',',[0 1 1]);
F.T = yyyymmdd2date(100*F.Expiry_yyyymm+15) - yyyymmdd2date(pricingDate);
F.T(1) = 0;
F = rmfield(F,{'Contract','Expiry_yyyymm'});

% interpolate
temp = [1:max(F.T)]';
F.Price = interp1q(F.T,F.Price,temp);
F.T = temp;

% futures at points of vol surfaces
Ts = sort(unique(V.T));
Fs = F.Price(ismember(F.T,Ts));


%% 2) interpolate vol curves at different expiries

plotCompletion = false;

spot = F.Price(1);
rr = -.4:.1:.4; % log returns

% desired grid
dK = 25;
minK = floor(spot*exp(rr(1)-.1)/dK)*dK;
maxK = ceil(spot*exp(rr(end)+.1)/dK)*dK;
KK = (minK:dK:maxK)';
rawVol = nan(length(KK),length(Ts));

for i = 1:length(Ts)
    
    idx = ismember(V.T,Ts(i));
    T = Ts(i)/365;
    
    K = V.K(idx);
    sigma = V.sigma(idx)/100;
    forward = F.Price(ismember(F.T,Ts(i)));
    
    dK = mode(diff(K));
    minK = floor(spot*exp(rr(1))/dK)*dK;
    maxK = ceil(spot*exp(rr(end))/dK)*dK;
    
    % interpolate, and put onto formulated grid
    [Kout, fout, oIdx] = interpolateSmile(K,sigma,spot,forward,T,dK,minK,maxK,plotCompletion);
    rawVol(:,i) = interp1(Kout,fout,KK);
    rawVol(isnan(rawVol(:,i)),i) = 0;
    
    if sum(oIdx) < length(oIdx) && plotCompletion
        title(['i = ' num2str(i)],'fontsize',14)
    end
    
end


% Put into risk-neutral prices by expiry (Q) 
[Q, vol, TT] = volSurface2rnPrices(rawVol,Ts,KK,dK,spot);

% Compute price matrix P
[P, E] = fromQ2P(Q);



%% final computations - the core of recovery theorem

% perron-frobenius root
[V, temp] = eig(P);
temp = diag(temp);
delta = max(temp(temp==real(temp)));    % delta solved
z = V(:,(temp == delta));               % z = D^(-1)*e solved
if z(1) < 0
    z = -z;
end

% sanity check
assert(mean(abs(P*z-delta*z)) < 1e-10)

% Master equation
% DP = delta*FD
% F = (1/delta)*DPD^(-1)

% solve for marginal utilities - this z is very ugly
D = diag(1./z);
F = (1/delta)*D*P*inv(D);

plot(F(6,:))
hold on
plot(P(6,:)/sum(P(6,:)),'g')

% bootstrap this distribution out... say a year
F4 = F^4;
plot(F4(6,:))



%% Let's see what comes out of Steve's P

P = [0.671,0.241,0.053,0.005,0.001,0.001,0.001,0.001,0.001,0,0;
0.28,0.396,0.245,0.054,0.004,0,0,0,0,0,0;
0.049,0.224,0.394,0.248,0.056,0.004,0,0,0,0,0;
0.006,0.044,0.218,0.39,0.25,0.057,0.003,0,0,0,0;
0.006,0.007,0.041,0.211,0.385,0.249,0.054,0.002,0,0,0;
0.005,0.007,0.018,0.045,0.164,0.478,0.276,0.007,0,0,0;
0.001,0.001,0.001,0.004,0.04,0.204,0.382,0.251,0.058,0.005,0;
0.001,0.001,0.001,0.002,0.006,0.042,0.204,0.373,0.243,0.055,0.004;
0.002,0.001,0.001,0.002,0.003,0.006,0.041,0.195,0.361,0.232,0.057;
0.001,0,0,0.001,0.001,0.001,0.003,0.035,0.187,0.347,0.313;
0,0,0,0,0,0,0,0,0.032,0.181,0.875];

% perron-frobenius root
[V, temp] = eig(P);
temp = diag(temp);
delta = max(temp(temp==real(temp)));    % delta solved
z = V(:,(temp == delta));               % z = D^(-1)*e solved
if z(1) < 0
    z = -z;
end

D = diag(1./z);
F = (1/delta)*D*P*inv(D);

% extrapolate returns forward
sigma = -log(.649)/5;   % backing out one-stdev from Steve's paper
ret = sigma*(-5:5);       % log returns
simpleRet = exp(ret)-1; % simple returns

F4 = F^4;
f4 = F4(6,:);
f1 = F(6,:);

sum(f4.*ret)    % expected log return (a bit higher than Ross)
sqrt(sum(f4.*ret.^2) - sum(f4.*ret)^2)  % volatility of log return (higher than Ross?)

sum(f4.*simpleRet)
sqrt(sum(f4.*simpleRet.^2) - sum(f4.*simpleRet)^2)


% Can we do this directly on log returns?
% we have a problem with variance ratios and return compounding

% different measures of expected annual returns. 

for i = 1:12
    tempF = F^i;
    
end



plot(F(6,:))
hold on
plot(P(6,:)/sum(P(6,:)),'g')

% bootstrap this distribution out... say a year
F4 = F^4;
plot(F4(6,:))
