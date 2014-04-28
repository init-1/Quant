function celFtsOut=aligndatastruct(varargin)
% Function: GetMRAReturnTS
% Description: Align the input fints objects s.t. 
%	(1) They all have the same common dates
%	(2) They all have the same common fields
%
%  Dates and fields that are not common to all objects will be taken out
%
% Inputs: 
%	The function accept variable number of fints object or its decendent
%
% Outputs: 
%	A cell array of align fints objects, all of which share the same dates and same fields
%
% Author: Bing Li
% Last Revision Date: 2010-10-22
% Verified by: 

celFtsOut = cell(size(varargin));
[celFtsOut{:}] = aligndata(varargin{:}, 'intersect');

% numData=nargin;
% 
% vecDate=[];
% vecField=[];
% 
% for i=1:numData
%     fts=varargin{i};
%     fn0=fieldnames(fts);
%     fn=fn0(4:end);
%     dt=getfield(fts, 'dates');
%     
%     vecDate=[vecDate; dt];
%     vecField=[vecField; fn0];
% end
% 
% vecUniqueDate=unique(vecDate);
% vecUniqueField=unique(vecField);
% 
% for i=1:numData
%     fts=varargin{i};
%     fn0=fieldnames(fts);
%     fn=fn0(4:end);
%     dt=getfield(fts, 'dates');
%     
%     vecUniqueDate=vecUniqueDate(ismember(vecUniqueDate, dt));
%     vecUniqueField=vecUniqueField(ismember(vecUniqueField, fn0));
% end
% 
% for i=1:numData
%     fts=varargin{i};
%     fn0=fieldnames(fts);
%     fn=fn0(4:end);
%     dt=getfield(fts, 'dates');
%     
%     vecIdxDate=ismember(dt,vecUniqueDate);
%     vecNonField=fn(~ismember(fn, vecUniqueField));
%     
%     ftsout=myfints();
%     ftsout.fints=fts.fints(vecIdxDate);
%     ftsout=rmfield(ftsout, vecNonField);
%     
%     celFtsOut{i}=ftsout;
% end