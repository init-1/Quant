function sfts = ftsnansum(varargin)
sfts = multiftsfun(varargin{:}, @(x)nansum(x,3));
