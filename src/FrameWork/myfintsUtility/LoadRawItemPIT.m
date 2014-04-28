function ftsArray = LoadRawItemPIT(secIds, itemId, startDate, endDate, numQtrs, varargin)
% FUNCTION: LoadRawItemPIT
%   ftsArray = LoadRawItemPIT(secIds, itemId, startDate, endDate, numQtrs, targetFreq)
% DESCRIPTION: Load the specified item time series for all securities in SecIds
%	and pack it as a 'myfints' object.
% INPUTS:
%	secIds      - A cell array of security id as defined in quantstaging.dbo.secmstr
%	itemId		- The itemID of the item defined in dataqa..itemmstr
%	startDate	- (string) Start time
%	endDate		- (string) End time
%   QtrsBack    - (int) number of quarters data to retrieve at every point in time
%   targetFreq  - (optional) the target freqency of the retrieved financial time series, can be: 
%           1, DAILY, Daily, daily, D, d
%			2, WEEKLY, Weekly, weekly, W, w
%			3, MONTHLY, Monthly, monthly, M, m
%			4, QUARTERLY, Quarterly, quarterly, Q, q
%			5, SEMIANNUAL, Semiannual, semiannual, S, s
%			6, ANNUAL, Annual, annual, A, a 
%
% OUTPUT:
%	ftsArray	- an array of myfints objects.

    %% Re-structure the data in the desired format
    % strip the quarter data out of sqlRet
    ret = [];
    ftsArray = cell(1,numQtrs);
    dates = [];
    for i = 1:numQtrs
        ftsArray{i} = DB.load(@fun, strcat('E',secIds), secIds, varargin{:});
        dates = union(ftsArray{i}.dates, dates);
    end
    dates = sort(dates);
    [ftsArray{:}] = aligndates(ftsArray{:}, dates);
    
    function r = fun(secIdList, targetFreq)
        if isempty(ret)
            db = DB('QuantStrategy');
            ret = db.runSql('fac.GetRawItemPIT',itemId,secIdList,startDate,endDate,numQtrs,targetFreq);
        end
        qtrIdx = (ret.QtrsBack == i-1);
        r.DataDate  = ret.DataDate(qtrIdx);
        r.SecId     = ret.SecId(qtrIdx);
        r.TargetVal = ret.TargetVal(qtrIdx);
    end
end
