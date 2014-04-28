function ofts = csrankcorr(iftsA, iftsB)
% Function: cscorr
% Description: Return the cross section rank correlation time series among all fields of a myfints
%
% Inputs: 
%	iftsA	- (myfints object) One inputs those cross sectional correlation is to be found
%	iftsB	- (myfints object) One inputs those cross sectional correlation is to be found
%	
% Outputs: 
%	A myfints object of cross section rank correlation
%
% Author: Louis Luo
% Last Revision Date: 2010-11-19
% Verified by: 

ofts = cscorr(iftsA, iftsB, 'type','spearman','rows','complete');
