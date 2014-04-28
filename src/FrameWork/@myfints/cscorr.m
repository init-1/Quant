function ofts=cscorr(iftsA, iftsB, varargin)
% Function: cscorr
% Description: Return the cross section correlation time series among all fields of a myfints
%
% Inputs: 
%	iftsA	- (myfints object) One inputs those cross sectional correlation is to be found
%	iftsB	- (myfints object) One inputs those cross sectional correlation is to be found
%	
% Outputs: 
%	A myfints object of cross section correlation
%
% Author: Bing Li
% Last Revision Date: 2010-10-22
% Verified by: 

option.type = 'Pearson';
option.rows = 'all';
option = Option.vararginOption(option, {'type', 'rows'}, varargin{:});
if isa(option.type, 'myfints')
    FTSASSERT(isaligneddata(iftsA, iftsB, option.type), 'weights of type FINTS not aligned with operands.');
    wt = fts2mat(csnorm(option.type));
    option.type = 'weighted';
elseif isnumeric(option.type)
    wt = option.type;
    FTSASSERT(isequal(size(wt), size(iftsA)), 'weights not compatible with operands.');
    option.type = 'weighted';
else
    FTSASSERT(ischar(option.type));
    wt = [];
end

f = @(x,y) mycscorr(x,y,wt,option);
ofts = biftsfun(iftsA, iftsB, f, 'cscorr');
ofts.desc = ['cross sectional ' option.type ' correlation'];

end

function rho = mycscorr(A, B, wt, option)
T   = size(A, 1);
rho = NaN(T, 1);
for i = 1:T
    X = A(i,:);
    Y = B(i,:);
    if isempty(wt)
        rho(i) = corr(X', Y', 'type', option.type, 'rows',option.rows);
    else  % calculate weighted correlation
        W = wt(i,:);
        rho(i) = (sum(W.*X.*Y) - sum(W.*X).*sum(W.*Y))...
              ./ sqrt((sum(W.*(X.^2)) - sum(W.*X).^2).*(sum(W.*(Y.^2)) - sum(W.*Y).^2));
    end
end
end % of the local function

