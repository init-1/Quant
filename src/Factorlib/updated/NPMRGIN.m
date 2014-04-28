classdef NPMRGIN < FacBase
    %NPMRGIN <a full descriptive name placed here>
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
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            NIBX = o.loadItem(secIds, 'D000686576', sDate, endDate, 4);
            revenue = o.loadItem(secIds, 'D000686629', sDate, endDate, 4);
            NIBX = ftsnanmean(NIBX{1:4});
            revenue = ftsnanmean(revenue{1:4});
            factorTS = NIBX ./ revenue;
        end
    end
end
