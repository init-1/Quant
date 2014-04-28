classdef GE_EP_Trend_RIG < GlobalEnhanced
    %GE_EP_Trend_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-5*370, 'yyyy-mm-dd');
            EPS_FY0 = o.loadItem(secIds, 'D000410178', sDate, endDate);
            EPS_FY1 = o.loadItem(secIds, 'D000411364', startDate, endDate);
            EPS_FY2 = o.loadItem(secIds, 'D000411365', startDate, endDate);
            EPS_FY3 = o.loadItem(secIds, 'D000411366', startDate, endDate);
            EPS_FY0_12 = o.lagfts(EPS_FY0, '12M');
            EPS_FY0_24 = o.lagfts(EPS_FY0, '24M');
            EPS_FY0_36 = o.lagfts(EPS_FY0, '36M');
            if o.isLive
                PR = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            
                      [EPS_FY0,EPS_FY0_12,EPS_FY0_24,EPS_FY0_36,EPS_FY1,EPS_FY2,EPS_FY3,PR] = ...
            aligndates(EPS_FY0,EPS_FY0_12,EPS_FY0_24,EPS_FY0_36,EPS_FY1,EPS_FY2,EPS_FY3,PR,gics.dates);
        
            growth = o.estGrowth({EPS_FY0_36 EPS_FY0_24 EPS_FY0_12 EPS_FY0 EPS_FY1 EPS_FY2 EPS_FY3});
            eps_hist = multiftsfun(EPS_FY0_36, EPS_FY0_24, EPS_FY0_12, EPS_FY0, @(x)(min(x,[],3)+nanmean(x,3))/2);
            factorTS = eps_hist .* (1+growth) .^ 2 ./ PR;
            factorTS = o.RIG(factorTS, gics);
        end
    end
end
