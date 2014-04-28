classdef MMT12M < FacBase
    %MMT12M <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:10

    methods (Access = protected)
        % build functions for backtest and live mode
        function factorTS = build(o, secIds, startDate, endDate)
             sdate = datestr(datenum(startDate)-370, 'yyyy-mm-dd');
             price = o.loadItem(secIds,'D001410415',sdate,endDate);
             ret12 = Price2Return(price, o.DCF('12M'));
             ret1 = Price2Return(price, o.DCF('1M'));
             ret1 = aligndates(ret1, ret12.dates);
             factorTS = ret12 - ret1;
        end
    end
end
