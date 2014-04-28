function res = neutralize(factor, GICS, nanfun, level, fieldname)
% factor is a myfints obj, and GICS should be either myfints or normal matrix,
% fun is the normal funtion that operates ignoring NaNs. having only one parameter
    if nargin < 5, fieldname = []; end
    if nargin < 4, level = 1; end
    
    % Check if input data are aligned
    if isa(GICS, 'myfints')
           FTSASSERT(isaligneddata(factor, GICS), 'GICS and factor are not aligned');
           GICS = fts2mat(GICS);
    end

    matFactor = fts2mat(factor);
    [T,N] = size(matFactor);
    if ischar(level) && ~isempty(GICS)
        FTSASSERT(strcmpi(level, 'customized'), 'level must either be a numeric or ''customized''');
        sid = GICS;
        sset = unique(sid);
        sset(isnan(sset)) = [];
    elseif isempty(GICS) || level == 0  % on whole universe
        sset = 1;
        sid  = ones(T,N);
    else  % on each sector
        sid = floor(double(GICS) ./ 100^(4-level)); 
        sset = unique(sid);
        sset(isnan(sset) | sset == 0) = [];
    end
    
    res = NaN(T,N);
    for s = 1:length(sset)  % iterate every sector
        incIdx = (sid == sset(s));
        a = matFactor;
        a(~incIdx) = NaN;
        a = nanfun(a);
        res(incIdx) = a(incIdx);
    end
   
    res = xtsreturn(factor, res, fieldname);
end
