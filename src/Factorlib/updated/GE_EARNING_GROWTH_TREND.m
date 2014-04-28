classdef GE_EARNING_GROWTH_TREND < GlobalEnhanced
    %GE_EARNING_GROWTH_TREND <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function [growth, EPS_HIST] = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-3*370, 'yyyy-mm-dd');
            EPS_FY0 = o.loadItem(secIds, 'D000410178', sDate, endDate);
            EPS_FY1 = o.loadItem(secIds, 'D000411364', startDate, endDate);
            EPS_FY2 = o.loadItem(secIds, 'D000411365', startDate, endDate);
            EPS_FY3 = o.loadItem(secIds, 'D000411366', startDate, endDate);
            
            EPS_FY0_12 = o.lagfts(EPS_FY0, '12M');
            EPS_FY0_24 = o.lagfts(EPS_FY0, '24M');
            EPS_FY0_36 = o.lagfts(EPS_FY0, '36M');
            
            [EPS_FY0, EPS_FY0_12, EPS_FY0_24, EPS_FY0_36] = aligndates(EPS_FY0, EPS_FY0_12, EPS_FY0_24, EPS_FY0_36, EPS_FY1.dates);
            
            growth = o.estGrowth({EPS_FY0_36, EPS_FY0_24, EPS_FY0_12, EPS_FY0, EPS_FY1, EPS_FY2, EPS_FY3});

            if nargin > 1
                f = @(x)(min(x,[],3)+nanmean(x,3)./2);
                EPS_HIST = multiftsfun(EPS_FY0,EPS_FY0_12,EPS_FY0_24,EPS_FY0_36, f);
            end
        end
    end
end
