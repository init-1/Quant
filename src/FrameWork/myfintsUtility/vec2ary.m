function [ary, varargout] = vec2ary(val, varargin)
% Syntax: [ary, s1, s2, ..., sN] = vec2ary(val, x1, x2, ..., xN)
    nDim = length(varargin);
    dim_n_sub = cell(1,nDim);
    aryDim = zeros(1,nDim);
    
    for i = 1:nDim
        x = varargin{i};
        if ischar(x)
            varargout{i} = x; dim_n_sub{i} = 1; 
            aryDim(i) = 1;
        else % either numeric or cell of strings
            [varargout{i},~,dim_n_sub{i}] = unique(x);
            aryDim(i) = length(varargout{i});
        end
    end
    
    ind = sub2ind(aryDim, dim_n_sub{:});
    if iscell(val)
        ary = cell(aryDim);
    else
        ary = nan(aryDim);
    end
    ary(ind) = val(:);
end
