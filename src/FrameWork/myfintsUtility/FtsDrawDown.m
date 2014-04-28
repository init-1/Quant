% this function calculate the drowdown of a return time series

function ofts = FtsDrawDown(ifts)

imat = fts2mat(ifts);
omat = zeros(size(imat));

omat(1,imat(1,:) < 0) = imat(1,imat(1,:) < 0);

for i = 2:size(omat,1)
    omat(i,:) = min(omat(i-1,:) + imat(i,:),0);
end

ofts = myfints(ifts.dates, omat, fieldnames(ifts,1));

return