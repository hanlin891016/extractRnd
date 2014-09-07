function [params_ini, error_ini] = gridSearch(objfun,ks,sigmas,mus)
% conducts a grid search for fminunc initialization.
%
% USAGE:    [params_ini, error_ini] = gridSearch(objfun,ks,sigmas,mus)
%
%
    
    % default search grid
    if ~exist('ks','var')
        ks = -3:.2:3;
        sigmas = 0:25:200;
        mus = -2000:200:2000;
    end
    
    params = setprod(ks,sigmas,mus);
    errors = nan(length(params),1);
    for i = 1:length(params)
        errors(i) = objfun(params(i,:));
    end
    
    [error_ini ,idx] = min(errors);
    params_ini = params(idx,:);
    
end
