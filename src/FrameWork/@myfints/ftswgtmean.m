% This function calculates the weighted mean of multiple myfints objects,
% The key feature of this function is that if any entry in any myfints is
% missing (NaN), the weight will be rescaled based on the non-missing observations
% Input: 
%      weight - <double / myfints> this is the weight of each myfints, if
%      the weight is static over time, weight is a 1 x N array, otherwise
%      it is a T x N myfints, where T = # of periods, N = # of Factors
%
%      varargin - <myfints> N myfints objects with size (T x M), where T =
%      # of periods, and M = # of fields. 


function ofts = ftswgtmean(weight, varargin)

assert(isaligneddata(varargin{:}), 'input myfints are not aligned');

if isa(weight, 'myfints')
    assert(isequal(weight.dates, varargin{1}.dates), 'the dates of weight is not aligned with the other myfints');
    weight = fts2mat(weight);
else
    assert(size(weight,1) == 1, 'the static weight has to be a row vector')
    weight = repmat(weight, [size(varargin{1},1),1]);
end
assert(size(weight,2) == numel(varargin), 'the size of the weight is not equal to the NO. of input myfints');

[T,M] = size(varargin{1});
N = numel(varargin);
varmat = NaN([size(varargin{1}),N]);

% assign the value from myfints to a 3D matrix
for i = 1:N
    varmat(:,:,i) = fts2mat(varargin{i});
end
wgtmat = repmat(reshape(weight, [T,1,N]), [1,M,1]);

% rescale the weight for non-missing values
wgtmat(isnan(varmat)) = NaN;
wgtsum = nansum(abs(wgtmat),3);
newwgtmat = wgtmat./repmat(wgtsum,[1,1,N]);
newwgtmat(isinf(newwgtmat)) = NaN;
allnanidx = all(isnan(varmat),3);

% calulate the weighted mean
wgtmean = nansum(newwgtmat.*varmat,3);
wgtmean(allnanidx) = NaN;

ofts = xtsreturn(varargin{1}, wgtmean);

return

