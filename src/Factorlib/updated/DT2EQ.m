classdef DT2EQ < FacBase
    %DT2EQ <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:06

    methods (Access = protected)
        % build functions for backtest and live mode
        function factorTS = build(o, secIds, startDate, endDate)
            sdate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            debt_lt  = o.loadItem(secIds, 'D000679633', sdate, endDate, 4);
            debt_cur = o.loadItem(secIds, 'D000679594', sdate, endDate, 4);
            equity   = o.loadItem(secIds, 'D000686133', sdate, endDate, 4);
            debt_lt  = ftsnanmean(debt_lt{1:4});
            debt_cur = ftsnanmean(debt_cur{1:4});
            equity   = ftsnanmean(equity{1:4});
            factorTS = (debt_lt+debt_cur) ./ equity;
        end
    end
end
