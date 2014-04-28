function regweight = GetSpecAdjustWgt(errfts,retfts,varargin)       
% estimate the specific adjustment weight from input error and return fts

option.scalebyRetVar = 0;
option.window = 12;
option = Option.vararginOption(option,{'method','scalebyRetVar','window'},varargin{:});

if ~isfield(option,'method')
    option.method = @(x)(ftsnanmean(ftsmovavg(x.^2,inf,1),ftsmovavg(x.^2,option.window,1))); %Average of Long Run variance & short run variance
end

errfts = lagts(errfts,1); % use lagged data to avoid look ahead bias
retfts = lagts(retfts,1); % use lagged data to avoid look ahead bias
retfts = bsxfun(@minus, retfts, csmean(retfts)); % de-mean the return

errVar = option.method(errfts);       

if option.scalebyRetVar
   retVar = option.method(retfts);
   regweight = bsxfun(@times,1./errVar,retVar);
else
   regweight = 1./errVar;
end       

regweight(1:min(12,option.window),:) = 1;
regweight(isinf(regweight)) = nan;

end