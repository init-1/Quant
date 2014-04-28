classdef MCAPSQRT < FacBase
    %MCAPSQRT <a full descriptive name placed here>
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
             factorTS = o.loadItem(secIds, 'D001410451', startDate, endDate);
             factorTS = uniftsfun(factorTS, @sqrt);
        end
    end
end
