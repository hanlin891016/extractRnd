function [P, E] = fromQ2P(Q)
% Converts real risk-neutral prices (Q, each column corresponding to a
% different expiry)
% 
% USAGE:    [P, E] = fromQ2P(Q)
% 
% E = Q(:,1:m)'*P - Q(:,2:(m+1))', the errors. 
% 
    
m = 9;      % number of states
iota = 1e-4;

% optimize on price matrix (reshaped into a vector). 
SSE = @(x) sqrt(mean(reshape(Q(:,1:m)'*reshape(x,m,m) - Q(:,2:(m+1))',m^2,1).^2));
x0 = reshape(eye(m),m^2,1);

% constraints: 
% 1) each period's state prices sum to at most 1
% 2) each state price non-negative (non-arbitrage). 
% 3) risk-free rate is ordered in the right direction across states

A1 = repmat(eye(m),1,m);
b1 = ones(m,1);
A2 = -eye(m^2);
b2 = -iota*ones(m^2,1);
A3 = [];
for i = 1:(m-1)
    temp = zeros(1,m);
    temp(i) = -1;
    temp(i+1) = 1;
    A3 = [A3; repmat(temp,1,m)];
end
b3 = iota*ones(m-1,1);

A = [A1;A2;A3];
b = [b1;b2;b3];

options = optimset('MaxFunEvals',100000,'MaxIter',10000,'Display','Iter',...
    'TolX',1e-12,'TolFun',1e-12,'AlwaysHonorConstraints','bounds');
P = reshape(fmincon(SSE,x0,A,b,[],[],[],[],[],options),m,m);

% errors
E = Q(:,1:m)'*P - Q(:,2:(m+1))';


end
