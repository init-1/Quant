function newFts = ftsmovstd(oldFts, window, ignoreNaN)
if nargin < 3
    ignoreNaN = 1;
end

if ignoreNaN
    fun = @(x) nanstd(x,[],1);
else
    fun = @(x) std(x,[],1);
end

newFts = ftsmovfun(oldFts, window, fun);

