classdef SICHG2VOLU < FacBase
    %SICHG2VOLU <a full descriptive name placed here>
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
            sDateSI = datestr(addtodate(datenum(startDate),-15,'M'),'yyyy-mm-dd');
            sDateVol = datestr(addtodate(datenum(startDate),-2,'M'),'yyyy-mm-dd');
            
            if o.isLive
                shortInterest = o.loadItem(secIds, 'D002201164', sDateSI, endDate);
                volume = o.loadItem(secIds, 'D001410430', sDateVol, endDate);
            else
                shortInterest = o.loadItem(secIds, 'D002201193', sDateSI, endDate);
                volume = o.loadItem(secIds, 'D001410430', sDateVol, endDate);
                % in the backtest mode, lag the short interest by 15 days
                shortInterest = o.lagfts(shortInterest, 15, NaN);
            end
            
            shortInterest = backfill(shortInterest, 30, 'entry');
            
            % calculate 12 months different of short interest
            lagDays = 365;
            shortInterestChg = shortInterest - o.lagfts(shortInterest, lagDays,  NaN);
            shortInterestChg = shortInterestChg(lagDays+1:end,:);
            
            volumeAvg = ftsmovavg(volume,25,1);
            volumeAvg = volumeAvg(25:end,:);
            
            shortInterestChg = aligndates(shortInterestChg, volumeAvg.dates);
            factorTS = shortInterestChg./volumeAvg;
        end
    end
end
