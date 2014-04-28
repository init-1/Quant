classdef SICHG2SH < FacBase
    %SICHG2SH <a full descriptive name placed here>
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
            sDate = datestr(addtodate(datenum(startDate),-15,'M'),'yyyy-mm-dd');
            sDateSh = datestr(addtodate(datenum(startDate),-10,'D'),'yyyy-mm-dd');
            
            if o.isLive
                shortInterest = o.loadItem(secIds, 'D002201164', sDate, endDate);
                shares = o.loadItem(secIds, 'D001410472', sDateSh, endDate);
            else
                shortInterest = o.loadItem(secIds, 'D002201193', sDate, endDate);
                shares = o.loadItem(secIds, 'D001410472', sDateSh, endDate);
                % in the backtest mode, lag the short interest by 15 days
                shortInterest = o.lagfts(shortInterest, 15, NaN);
            end
            
            shortInterest = backfill(shortInterest, 30, 'entry');
            
            % calculate 12 months different of short interest
            lagDays = 365;
            shortInterestChg = shortInterest - o.lagfts(shortInterest, lagDays, NaN);
            shortInterestChg = shortInterestChg(lagDays+1:end,:);
            
            shortInterestChg = aligndates(shortInterestChg, shares.dates);
            factorTS = shortInterestChg./shares;
        end
    end
end
