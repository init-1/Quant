function newFts = ftsmovsum(oldFts, window, ignoreNaN)
if nargin < 3
    ignoreNaN = 1;
end

if ignoreNaN
    fun = @(x) nansum(x,1);
else
    fun = @(x) sum(x,1);
end

newFts = ftsmovfun(oldFts, window, fun);

