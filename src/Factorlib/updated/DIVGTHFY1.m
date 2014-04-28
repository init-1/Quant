classdef DIVGTHFY1 < GTHFY1_Base
    %DIVGTHFY1 <a full descriptive name placed here>
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
            DIV_FY0 = 'D000432098';
            DIV_FY1 = 'D000434944';
            factorTS = o.define(DIV_FY0, DIV_FY1, secIds, startDate, endDate);
        end
        
        function factorTS = buildLive(o, secIds, endDate)
            DIV_FY0 = 'D000437351';
            DIV_FY1 = 'D000446805';
            factorTS = o.define(DIV_FY0, DIV_FY1, secIds, endDate, endDate);
        end
    end
end
