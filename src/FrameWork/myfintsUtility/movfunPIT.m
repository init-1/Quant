function oftsary = movfunPIT(iftsary, window, fun)
noftsary = length(iftsary)-window+1;
FTSASSERT(noftsary > 0);

oftsary = cell(1, noftsary);
for i = 1:noftsary
    oftsary{i} = multiftsfun(iftsary{i:i+window-1}, @(x)fun(x,3));
end


