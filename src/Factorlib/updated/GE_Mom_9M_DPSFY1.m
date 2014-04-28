classdef GE_Mom_9M_DPSFY1 < GlobalEnhanced
    %GE_Mom_9M_DPSFY1 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-24*31, 'yyyy-mm-dd');
            FY0 = o.loadItem(secIds, 'D000431933', sDate, endDate);
            FY1 = o.loadItem(secIds, 'D000415183', sDate, endDate);
            FY2 = o.loadItem(secIds, 'D000415184', sDate, endDate);
            DPS_FY1_MD = o.loadItem(secIds, 'D000410724', sDate, endDate);
            DPS_FY2_MD = o.loadItem(secIds, 'D000410725', sDate, endDate);
            DPS_FY0_RV = o.loadItem(secIds, 'D000410146', sDate, endDate);
            
            if o.isLive
                EPS_FY0_PR = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                EPS_FY0_PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            
            All = cellfun(@(x){backfill(x,o.DCF('12M'),'entry')}, {FY0,FY1,FY2,DPS_FY1_MD,DPS_FY2_MD,DPS_FY0_RV,EPS_FY0_PR});
            [FY0,FY1,FY2,DPS_FY1_MD,DPS_FY2_MD,DPS_FY0_RV,EPS_FY0_PR] = All{:};
            
            mon = '9M';
            momentum = o.IBES_momentum(FY0, FY1, FY2, DPS_FY0_RV, DPS_FY1_MD, DPS_FY2_MD, o.DCF(mon));
            momentum = aligndates(momentum, EPS_FY0_PR.dates);
            momentum(EPS_FY0_PR <= 0) = NaN;
            factorTS = momentum ./ EPS_FY0_PR;
        end
    end
end
