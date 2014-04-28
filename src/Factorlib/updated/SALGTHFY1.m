classdef SALGTHFY1 < GTHFY1_Base
    %SALGTHFY1 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:13

    methods (Access = protected)
        % build functions for backtest and live mode
        function factorTS = build(o, secIds, startDate, endDate)
            SAL_FY0 = 'D000432194';
            SAL_FY1 = 'D000436864';
            factorTS = o.define(SAL_FY0, SAL_FY1, secIds, startDate, endDate);
        end
        
        function factorTS = buildLive(o, secIds, endDate)
            SAL_FY0 = 'D000437545';
            SAL_FY1 = 'D000453285';
            factorTS = o.define(SAL_FY0, SAL_FY1, secIds, endDate, endDate);
        end
    end
end
