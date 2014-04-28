function newFts = ftsmovzscore(oldFts, window, ignoreNaN,truncateVal)
% FUNCTION: ftsmovstd
% DESCRIPTION: Calculate the moving z-score of a time series, NaN will be
% ignored in calculation if ignoreNaN = 1
% INPUTS:
%	oldFts - (myfints object) 
%   window is the window for calculation, Inf will indicate expanding window
%   truncateVal is the windsorization value
%
% OUTPUT:
%	newFts - The resulting myfints object
%
% Author: Eddie Pong
% Last Revision Date: 2011-04-13
% Vertified by: 
%

stdFts=ftsmovstd(oldFts,window,ignoreNaN);
avgFts=ftsmovavg(oldFts,window,ignoreNaN);

newFts=(oldFts-avgFts)./stdFts;

newFts(fts2mat(newFts)>truncateVal)=truncateVal;
newFts(fts2mat(newFts)<-truncateVal)=-truncateVal;



