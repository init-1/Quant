function newFts = ftsema(oldFts, window, ignoreNaN)
% exponential moving average for myfints
if window == inf, window = length(oldFts)-1; end
FTSASSERT(length(oldFts) > window, 'not enough data points to perform calculation');

if nargin < 3
    ignoreNaN = 1;
end

K = round(3.45*(window+1)); % the weight after K = 3.45*(N+1) can be ignored
K = min(K, length(oldFts));
alpha = 2/(window+1);
power = (K-1:-1:0)';
weight = (1-alpha).^power;

oldData = fts2mat(oldFts);
newData = nan(size(oldData));

if ignoreNaN == 1
    fun = @nansum;
else
    fun = @sum;
end

for i = 1:length(oldFts)
    len = min(i,K);
    newData(i,:) = alpha*fun(oldData(i-len+1:i,:).*repmat(weight(end-len+1:end,:),[1,size(oldData,2)]));
end

newFts = myfints(oldFts.dates,newData,fieldnames(oldFts,1));
