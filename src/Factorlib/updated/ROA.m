classdef ROA < FacBase
    %ROA <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:12

    methods (Access = protected)
        % build functions for backtest and live mode
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            NIBX = o.loadItem(secIds, 'D000686576', sDate, endDate, 4);
            asset = o.loadItem(secIds, 'D000686130', sDate, endDate, 4);
            NIBX = ftsnanmean(NIBX{1:4});
            asset = ftsnanmean(asset{1:4});
            factorTS = NIBX ./ asset;
        end
    end
end
