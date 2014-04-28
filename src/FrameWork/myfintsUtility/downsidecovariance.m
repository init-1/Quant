function y = downsidecovariance(Y, m)

%   Y = DOWNSIDECOVARIANCE(Y) returns the downside covariance for columns
%   of variable Y.
%
%   Y = DOWNSIDECOVARIANCE(Y, m) returns the downside covariance using
%   vector m as expected value for columns of variable Y.
%
% % ======================================================================
%
%   Downside covariance is defined as
%                   E[min(yi - mi, 0) min(yj - mj, 0)]
%   If omitted, m is the sampe mean of Y.
%
% % ======================================================================
%
%   See also VAR, STD, COV.
%
% % ======================================================================
%
%   Author: Francesco Pozzi
%   E-mail: francesco.pozzi@anu.edu.au
%   Date: 26 April 2010
%
% % ======================================================================
%

% Check input
ctrl1 = isnumeric(Y) & isreal(Y);
if ctrl1
  ctrl2 = ~any(isnan(Y(:))) & ~any(isinf(Y(:))) & (length(size(Y)) < 3);
  if ~ctrl2
  error('Check Y: no infinite or nan values are allowed! Y must be either a vector or a 2D matrix.')
  end
else
  error('Check Y: it needs be either a vector or a 2D matrix of real numbers!')
end

[T, N] = size(Y);

if nargin == 2
  ctrl1 = isvector(m) & isreal(m);
  if ctrl1
    ctrl2 = ~any(isnan(m(:))) & ~any(isinf(m(:)));
    if ctrl2
      if length(m) == N
        m = m(:)';            % a is row vector
      elseif length(m) == 1
        m = m * ones(1, N);
      end
    else
      error('Check m: no infinite or nan values are allowed!')
    end
  else
    error('Check m: it needs be a vector of real numbers!')
  end
else
  m = mean(Y);
end

y = Y - repmat(m, T, 1);
inds = find(y > 0);
y(inds) = 0;
y = y' * y / (T - 1);
y = 0.5 * (y + y');
 
 
