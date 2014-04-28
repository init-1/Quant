function facTS = LoadFactorDecile(secIds, factorId, startDate, endDate, IsLive, targetFreq, nBucket, isProd, bmhd)

if nargin < 7
    nBucket = 10;
    isProd = 0;
elseif nargin < 8
    isProd = 0;
end

interval = 100/nBucket;

if isProd == 0
    facTS = LoadFactorTS(secIds, factorId, startDate, endDate, IsLive);
elseif isProd == 1
    facTS = LoadFactorTSProd(secIds, factorId, startDate, endDate, IsLive);
end

if exist('bmhd','var')
    facTS = alignto(bmhd, facTS);
    facTS(isnan(bmhd)) = nan;
end

facTS = csRankPrc(facTS, 'ascend');

facTS(:,:) = ceil(fts2mat(facTS)./interval);

if ~isnan(targetFreq)
    facTS = aligndates(facTS, targetFreq);
end