classdef GE_EY_TREND < GE_EARNING_GROWTH_TREND
    %GE_EY_TREND <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            [growth,EPS_HIST] = build@GE_EARNING_GROWTH_TREND(o, secIds, startDate, endDate);
            factorTS = EPS_HIST .* (1+growth) .^ 2;
            
            if o.isLive
                PR = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
      
            dates = o.genDates(startDate, endDate, o.freq);    % 'Busday', 0);
            [factorTS, PR] = aligndata(factorTS, PR, dates);
            factorTS = factorTS ./ PR;
        end
    end
end
