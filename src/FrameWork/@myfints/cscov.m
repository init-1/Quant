function ofts=cscov(iftsA, iftsB, varargin)
% Function: cscov(A, B, ...)
% Description: Return the cross section covariance time series among all fields of a myfints
%
% Inputs: 
%    A	- The first fts of correlation function
%    B	- The second fts of correlation function
%    ...	- The flags of calculation:
%        'ignorenan' - ignore nan elements appear in either A or B
%
%	
% Outputs: 
%	A myfints object of cross section covariance
%
% Author: Bing Li
% Last Revision Date: 2010-10-22
% Verified by: 

f = @(x,y) mycscov(x,y,varargin{:});
ofts = biftsfun(iftsA, iftsB, f, 'cscov');
ofts.desc = 'cross sectional covariance';

end

function C = mycscov(A, B, varargin)
[~,N] = size(A);

if (ismember('ignorenan', varargin))
    mf = @nanmean;
    sf = @nansum;
    N = sum(~isnan(A) & ~isnan(B),2); % N is Tx1
else
    mf = @mean;
    sf = @sum;
    % N still is the scalar obtained at start
end    

meanA = mf(A, 2);
meanB = mf(B, 2);
C = sf(bsxfun(@minus, A, meanA) .* bsxfun(@minus, B, meanB),2) ./ (N-1);
end
