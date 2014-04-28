classdef EARGTHFY1 < GTHFY1_Base
    %EARGTHFY1 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:07

    methods (Access = protected)
        % build functions for backtest and live mode
        function factorTS = build(o, secIds, startDate, endDate)
            EPS_FY0 = 'D000432130';
            EPS_FY1 = 'D000435584';
            factorTS = o.define(EPS_FY0, EPS_FY1, secIds, startDate, endDate);
        end
        
        function factorTS = buildLive(o, secIds, endDate)
            EPS_FY0 = 'D000437417';
            EPS_FY1 = 'D000448965';
            factorTS = o.define(EPS_FY0, EPS_FY1, secIds, endDate, endDate);
        end
    end
end
