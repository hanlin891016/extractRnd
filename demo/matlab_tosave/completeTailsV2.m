function [K, f, originalIdx, targetVal, achievedVal] = completeTailsV2(rnPmf,K,plotCompletion,minK,maxK,options)
% Very similar to "completeTails, but matching on multiple ending points rather than just 
% two. 
% 

% setting parameters
pts = 5;    % number of points for training on each tail
eta = 1e-20; % we don't want the shape parameter to look ridiculous

%% Inputs

    if length(rnPmf) ~= length(K)
        error('length of inputs don''t match.');
    end
    
    if ~exist('plotCompletion','var')
        plotCompletion = false;
    end
    
    if ~exist('options','var')
%         options = optimset('MaxIter',1000,'MaxFunEvals',10000,'TolFun',1e-12,'TolX',1e-16,'Display','iter');
        options = optimset('MaxIter',1000,'MaxFunEvals',10000,'TolFun',1e-12,'TolX',1e-16);
    end
    
    dK = unique(diff(K));
    if length(dK) > 1
        error('input grid is not uniform. Exiting.')
    end
    area = dK*sum(rnPmf);
    
    if area > 1
        error(['area = ' num2str(area)])
    end
    
    % set up points for training
    alphaL = (1-area)*(2/3);
    alphaR = 1 - (1-area)*(1/3);
    
    KleftTrain = K(1:pts);
    KrightTrain = K(end-pts+1:end);
    fleftTrain = rnPmf(1:pts);
    frightTrain = rnPmf(end-pts+1:end);
    
    %% grid search + unconstrained minimization    
    
    % fit right tail
    errR = @(x)(gevcdf(K(end),x(1),x(2),x(3))/alphaR - 1)^2 + ...
        sum((gevpdf(KrightTrain,x(1),x(2),x(3))./frightTrain - 1).^2) + ...
        eta*x(1)^2;
    x0 = gridSearch(errR);
    xR = fminunc(errR,x0,options);
    
    if errR(xR) > errR(x0)
        error('fmincon going up hill in right tail, something not right')
    end
    
    
    % fit left tail
    errL = @(x)(gevcdf(-K(1),x(1),x(2),x(3))/(1-alphaL)-1)^2 + ...
        sum((gevpdf(-KleftTrain,x(1),x(2),x(3))./fleftTrain - 1).^2) + ...
        eta*x(1)^2;
    x0 = gridSearch(errL);
    xL = fminunc(errL,x0,options);
    
    if errL(xL) > errL(x0)
        error('fmincon going up hill in left tail, something not right')
    end
    
    targetVal(:,1) = [1-alphaL fleftTrain']';
    achievedVal(:,1) = [gevcdf(-K(1),xL(1),xL(2),xL(3)) gevpdf(-KleftTrain,xL(1),xL(2),xL(3))']';
    targetVal(:,2) = [alphaR frightTrain']';
    achievedVal(:,2) = [gevcdf(K(end),xR(1),xR(2),xR(3)) gevpdf(KrightTrain,xR(1),xR(2),xR(3))']';

    % 3.1) visualize completion
    if plotCompletion
        
        Kleft = minK:dK:(K(pts)-dK);
        fleft = gevpdf(-Kleft,xL(1),xL(2),xL(3));
        
        Kright = (K(end-pts+1)+dK):dK:maxK;
        fright = gevpdf(Kright,xR(1),xR(2),xR(3));
        
        h = figure;
        plot(K,rnPmf,'go')
        hold on
        plot(Kleft,fleft,'--')
        plot(Kright,fright,'--')
    end
    
    % 3.2) connect the pmf!
    Kleft = minK:dK:(K(1)-dK);
    Kright = (K(end)+dK):dK:maxK;
    fleft = gevpdf(-Kleft,xL(1),xL(2),xL(3));
    fright = gevpdf(Kright,xR(1),xR(2),xR(3));
    
    f = [fleft rnPmf' fright]';
    K = [Kleft K' Kright]';
    
    % these are original data
    originalIdx = zeros(size(K));
    originalIdx(length(Kleft)+1:(length(Kleft)+length(K)))=1;
    
