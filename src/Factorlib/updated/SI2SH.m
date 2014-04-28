classdef SI2SH < FacBase
    %SI2SH <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:13
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('D');
            sDate = datestr(datenum(startDate)-60,'yyyy-mm-dd');
            
            if o.isLive
                shortInterest = o.loadItem(secIds, 'D002201164', sDate, endDate);
                shares = o.loadItem(secIds, 'D001410472', sDate, endDate);
            else
                shortInterest = o.loadItem(secIds, 'D002201193', sDate, endDate);
                shares = o.loadItem(secIds, 'D001410472', sDate, endDate);
                % in the backtest mode, lag the short interest by 15 days
                shortInterest = o.lagfts(shortInterest, 15, NaN);
            end
            
            shortInterest = backfill(shortInterest, 30, 'entry');
            factorTS = shortInterest./shares;
        end
    end
end
