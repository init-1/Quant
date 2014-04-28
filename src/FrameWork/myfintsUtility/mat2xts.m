function ts = mat2xts(date, val, varargin)
% Syntax: fts = mat2fts(date, val, flds1, flds2, ..., fldsn)
% Returns a n+1 (date, flds1, flds2, ..., fldsn) dimensional xts
    if isempty(date), ts = xts; return; end
    FTSASSERT(nargin >= 3, 'No fields specified');
    
    date = datenum(date);
    n = length(varargin);
    flds = cell(1, n);
    [val, date, flds{:}] = vec2ary(val, date, varargin{:});

    for i = 1:n
        if ~iscell(flds{i})  % then assume it must be numeric or logical
            if isrow(flds{i}), flds{i} = flds{i}'; end
            str = num2str(flds{i});
            flds{i} = strtrim(mat2cell(str, ones(size(str,1),1)));
        end
    end
    
    if ndims(val) == 2
        ts = myfints(date, val, flds{1});
    else
        ts = xts(date, val, flds{:});
    end
end
