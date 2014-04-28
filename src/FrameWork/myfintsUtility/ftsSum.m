function sfts = ftsSum(varargin)
sfts = multiftsfun(varargin{:}, @(x)sum(x,3));
end
