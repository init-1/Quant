classdef MMT9M < FacBase
    %MMT9M <a full descriptive name placed here>
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
             sdate = datestr(datenum(startDate)-278, 'yyyy-mm-dd');
             price = o.loadItem(secIds,'D001410415',sdate,endDate);
             ret9 = Price2Return(price, o.DCF('9M'));
             ret1 = Price2Return(price, o.DCF('1M'));
             ret1 = aligndates(ret1, ret9.dates);
             factorTS = ret9 - ret1;
        end
    end
end
