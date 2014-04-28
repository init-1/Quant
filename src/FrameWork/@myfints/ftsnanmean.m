function sfts = ftsnanmean(varargin)
sfts = multiftsfun(varargin{:}, @(x)nanmean(x,3));

