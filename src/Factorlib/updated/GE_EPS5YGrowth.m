classdef GE_EPS5YGrowth < GlobalEnhanced
    %GE_EPS5YGrowth <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            factorTS = o.loadItem(secIds, 'D000110479', startDate, endDate);
        end
    end
end
