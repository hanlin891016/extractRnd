function [K, f, originalIdx, targetVal, achievedVal] = completeTails(rnPmf,K,plotCompletion,minK,maxK,options)
    
    if length(rnPmf) ~= length(K)
        error('length of inputs don''t match.');
    end
    
    if ~exist('plotCompletion','var')
        plotCompletion = false;
    end
    
    if ~exist('options','var')
        options = optimset('MaxIter',1000,'MaxFunEvals',10000,'TolFun',1e-12,'TolX',1e-16,'Display','iter');
%         options = optimset('MaxIter',1000,'MaxFunEvals',10000,'TolFun',1e-12,'TolX',1e-16);
    end
    
    dK = unique(diff(K));
    if length(dK) > 1
        error('input grid is not uniform. Exiting.')
    end
    area = dK*sum(rnPmf);
    
    if area > 1
        error(['area = ' num2str(area)])
    end
    
    % set up cutoff points
    alpha1L = (1-area)*(2/3);
    alpha0L = alpha1L + 0.03;
    alpha1R = 1 - (1-area)*(1/3);
    alpha0R = alpha1R - 0.03;
    
    rnCdf = alpha1L + dK*cumsum(rnPmf); % we pretend the pmf bar is the right of each K-point
    
    % find the points closest to desired alpha0L, alpha0R range
    [~,idx] = min(abs(rnCdf - alpha0L));
    K0L = K(idx);
    K1L = K(1);
    alpha0L = rnCdf(idx);   % revise
    f0L = rnPmf(idx);       % this should be approximately correct
    f1L = rnPmf(1);
    
    [~,idx] = min(abs(rnCdf - alpha0R));
    K0R = K(idx);
    K1R = K(end);
    alpha0R = rnCdf(idx);   % revise
    f0R = rnPmf(idx);
    f1R = rnPmf(end);
    
    
    %% unconstrained search
    
    
    eta = 1e-20; % we don't want the shape parameter to look ridiculous
    
    % fit right tail
    errR = @(x)(gevcdf(K0R,x(1),x(2),x(3))/alpha0R-1)^2 + ...
        (gevpdf(K0R,x(1),x(2),x(3))/f0R-1)^2 + (gevpdf(K1R,x(1),x(2),x(3))/f1R-1)^2 + eta*x(1)^2;
    x0 = gridSearch(errR);
    xR = fminunc(errR,x0,options);
    
    if errR(xR) > errR(x0)
        error('fmincon going up hill in right tail, something not right')
    end
    
    
    % fit left tail
    errL = @(x)(gevcdf(-K0L,x(1),x(2),x(3))/(1-alpha0L)-1 )^2 + ...
        (gevpdf(-K0L,x(1),x(2),x(3))/f0L-1)^2 + (gevpdf(-K1L,x(1),x(2),x(3))/f1L-1)^2 + eta*x(1)^2;
    x0 = gridSearch(errL);
    xL = fminunc(errL,x0,options);
    
    if errL(xL) > errL(x0)
        error('fmincon going up hill in left tail, something not right')
    end
    
    targetVal(:,1) = [1-alpha0L f0L f1L]';
    achievedVal(:,1) = [gevcdf(-K0L,xL(1),xL(2),xL(3)) gevpdf(-K0L,xL(1),xL(2),xL(3)) gevpdf(-K1L,xL(1),xL(2),xL(3))]';
    targetVal(:,2) = [alpha0R f0R f1R]';
    achievedVal(:,2) = [gevcdf(K0R,xR(1),xR(2),xR(3)) gevpdf(K0R,xR(1),xR(2),xR(3)) gevpdf(K1R,xR(1),xR(2),xR(3))]';

    % 3.1) visualize completion
    if plotCompletion
        
        Kleft = minK:dK:(K0L-dK);
        fleft = gevpdf(-Kleft,xL(1),xL(2),xL(3));
        
        Kright = (K0R+dK):dK:maxK;
        fright = gevpdf(Kright,xR(1),xR(2),xR(3));
        
        h = figure;
        plot(K,rnPmf,'go')
        hold on
        plot(Kleft,fleft,'--')
        plot(Kright,fright,'--')
    end
    
    % 3.2) connect the pmf!
    Kleft = minK:dK:(K1L-dK);
    fleft = gevpdf(-Kleft,xL(1),xL(2),xL(3));
    Kright = (K1R+dK):dK:maxK;
    fright = gevpdf(Kright,xR(1),xR(2),xR(3));
    
    f = [fleft rnPmf' fright]';
    K = [Kleft K' Kright]';
    
    % these are original data
    originalIdx = zeros(size(K));
    originalIdx(length(Kleft)+1:(length(Kleft)+length(K)))=1;
    
