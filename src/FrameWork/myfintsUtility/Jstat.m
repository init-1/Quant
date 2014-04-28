% monotonicity test - J statistics on mean of return series 

function stat = Jstat(ifts)

assert(size(ifts,2) > 1, 'input myfints must have more than two fields');

meanval = nanmean(fts2mat(ifts),1);

delta = meanval(2:end) - meanval(1:end-1);

stat = min(delta);

return