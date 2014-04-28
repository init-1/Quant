function facTS = LoadRawItemDecile(secIds, itemId, startDate, endDate, targetFreq, nBucket, bmhd)

if nargin < 6
    nBucket = 10;
end

interval = 100/nBucket;

facTS = LoadRawItemTS(secIds, itemId, startDate, endDate, targetFreq);

if exist('bmhd','var')
    facTS = alignto(bmhd, facTS);
    facTS(isnan(bmhd)) = nan;
end

facTS = csRankPrc(facTS, 'ascend');

facTS(:,:) = ceil(fts2mat(facTS)./interval);

end