function [riskcon, variance] = CalcRiskContrib(wgt, faccov, facexp, specrisk)
% calcualte the risk contribution and total variance based on input weight and risk measure
nasset = numel(wgt);
nfac = round(sqrt(numel(faccov)));

newwgt = reshape(wgt,[1,nasset]);
newspecrisk = reshape(specrisk, [1, nasset]);
newfaccov = nan(nfac,nfac);
newfacexp = nan(nasset,nfac);
for i = 1:nfac
    newfaccov(i,:) = faccov(1,:,i);
    newfacexp(:,i) = facexp(1,:,i); 
end

specvar = zeros(nasset, nasset); 
specvar(1:nasset+1:end) = newspecrisk.^2;

specvar(isnan(specvar)) = 0;
newfacexp(isnan(newfacexp)) = 0;
newwgt(isnan(newwgt)) = 0;

assetcov = newfacexp*newfaccov*(newfacexp') + specvar;
wgtcov = newwgt'*newwgt.*assetcov;

riskcon = nansum(wgtcov,1);
variance = sum(riskcon);

end