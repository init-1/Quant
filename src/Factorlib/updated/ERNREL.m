classdef ERNREL < FacBase
    %ERNREL <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:08

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            asset     = o.loadItem(secIds, 'D000686130', sDate, endDate, 8);
            liability = o.loadItem(secIds, 'D000686138', sDate, endDate, 8);
            cash      = o.loadItem(secIds, 'D000679586', sDate, endDate, 8);
            debt_lt   = o.loadItem(secIds, 'D000679633', sDate, endDate, 8);
            debt_cur  = o.loadItem(secIds, 'D000679594', sDate, endDate, 8);
            
            tot_asset  = ftsnanmean(asset{1:4});
            dasset     = tot_asset                  - ftsnanmean(asset{5:8});
            dliability = ftsnanmean(liability{1:4}) - ftsnanmean(liability{5:8});
            dcash      = ftsnanmean(cash{1:4})      - ftsnanmean(cash{5:8});
            ddebt_lt   = ftsnanmean(debt_lt{1:4})   - ftsnanmean(debt_lt{5:8});
            ddebt_cur  = ftsnanmean(debt_cur{1:4})  - ftsnanmean(debt_cur{5:8});
            
            accrual  = (dasset - dcash) - (dliability - ddebt_cur - ddebt_lt);
            factorTS = accrual ./ tot_asset;
        end
    end
end
