function newFts = ftsmovavg(oldFts, window, ignoreNaN)
if nargin < 3
    ignoreNaN = 1;
end

if ignoreNaN
    fun = @(x) nanmean(x,1);
else
    fun = @(x) mean(x,1);
end

newFts = ftsmovfun(oldFts, window, fun);
