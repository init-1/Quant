classdef ROIC < FacBase
    %ROIC <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:12

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            EBITDA   = o.loadItem(secIds, 'D000679559', sDate, endDate, 4);
            dep      = o.loadItem(secIds, 'D000685797', sDate, endDate, 4);
            debt_lt  = o.loadItem(secIds, 'D000679633', sDate, endDate, 4);
            debt_cur = o.loadItem(secIds, 'D000679594', sDate, endDate, 4);
            equity   = o.loadItem(secIds, 'D000686133', sDate, endDate, 4);
            cash     = o.loadItem(secIds, 'D000679586', sDate, endDate, 4);
            EBITDA   = ftsnanmean(EBITDA{1:4});
            dep      = ftsnanmean(dep{1:4});
            debt_lt  = ftsnanmean(debt_lt{1:4});
            debt_cur = ftsnanmean(debt_cur{1:4});
            equity   = ftsnanmean(equity{1:4});
            cash     = ftsnanmean(cash{1:4});

            bc = cellfun(@(x){backfill(x,o.DCF('6M'),'entry')}, {EBITDA, dep, debt_lt, debt_cur, equity, cash});
            [EBITDA, dep, debt_lt, debt_cur, equity, cash] = bc{:};
            factorTS = (EBITDA-dep) ./ (debt_lt+debt_cur+equity-cash);
        end
    end
end
