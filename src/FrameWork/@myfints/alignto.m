function varargout = alignto(targetfts, varargin)
% this function align all myfints to the first input - the targetfts, the
% resulted output will have the same dates and fields as the targetfts.

dates = targetfts.dates;
fields = fieldnames(targetfts,1);

varargout = cell(size(varargin));

[varargout{:}] = aligndates(varargin{:}, dates);
for i = 1:numel(varargin)
    varargout{i} = padfield(varargout{i}, fields);
end

end