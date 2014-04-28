classdef ROAFY1FY0 < BrokerFacBase
    %ROAFY1FY0 <a full descriptive name placed here>
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
            factorTS = build@BrokerFacBase(o, secIds, startDate, endDate, 'D002420084');
        end
    end
end
