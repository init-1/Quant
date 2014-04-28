function [alpha, predbeta] = PredFacRtn(beta, grpfacts, alphafacidx, predmethod, predwindow)
% this funcion make forecast on the factor return

lagbeta = lagts(beta,1,nan);
switch predmethod
    case 'SMA'
        predbeta = ftsmovavg(lagbeta,predwindow,1);
    case 'EMA'
        predbeta = ftsema(lagbeta,predwindow,1);
    otherwise
        error('invalid factor return forecasting method');
end

alpha = ftswgtmean(predbeta(:,alphafacidx), grpfacts{alphafacidx}); 
% note ftswgtmean will scale the predbeta to be sum to 1!
% so rescale the alpha back to the scale of return
sumbeta = cssum(abs(predbeta(:,alphafacidx)));
alpha = bsxfun(@times, alpha, sumbeta); 

end