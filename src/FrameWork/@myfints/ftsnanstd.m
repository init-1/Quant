function sfts = ftsnanstd(varargin)
f = @(x) nanstd(x,[],3);
sfts = multiftsfun(varargin{:}, f);

