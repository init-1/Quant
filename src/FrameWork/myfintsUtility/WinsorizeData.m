function omat = WinsorizeData(imat, varargin)
% this function performs data quality check on input matrix
option.pct = 0.02; % the percentile to exclude when calculating the standard deviation
option.nsigma = 5; % the one-side number of standard deviation as cutoff point
option.dim = 2; % {0,1,2} the dimension to winsorize data, 0 stands for the entire matrix

option = Option.vararginOption(option, {'pct','nsigma','dim'}, varargin{:});

assert(option.pct >= 0 && option.pct <= 1, 'percentile has to be within [0,1]');
assert(option.nsigma > 0, 'nsigma must > 0');
assert(option.dim >= 0 && option.dim < 3, 'dim must be in {0,1,2}');


%% deal with input
pct = option.pct;
nsigma = option.nsigma;
dim = option.dim;


% step 1 - take away potential outliers before calculating sigma 
if option.dim == 0
    imat_tmp = reshape(imat, [numel(imat), 1]);
    dim = 1;
else
    imat_tmp = imat;
end
lb = quantile(imat_tmp, pct, dim);
ub = quantile(imat_tmp, 1 - pct, dim);
imat_tmp(bsxfun(@ge, imat_tmp, ub)) = NaN;
imat_tmp(bsxfun(@le, imat_tmp, lb)) = NaN;

% step 2 - calculate miu and sigma
miu = nanmean(imat_tmp,dim);
sigma = nanstd(imat_tmp,[],dim);

% step 3 - winsorization
omat = imat;
omat(bsxfun(@gt, imat, miu+nsigma*sigma)) = NaN; 
omat(bsxfun(@lt, imat, miu-nsigma*sigma)) = NaN; 


end
