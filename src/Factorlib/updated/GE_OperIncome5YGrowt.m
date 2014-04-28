classdef GE_OperIncome5YGrowt < GlobalEnhanced
    %GE_OperIncome5YGrowt <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            factorTS = o.loadItem(secIds, 'D000110891', startDate, endDate);
        end
    end
end
