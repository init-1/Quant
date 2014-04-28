classdef GE_DPS3YGrowth < GlobalEnhanced
    %GE_DPS3YGrowth <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            factorTS = o.loadItem(secIds, 'D000110466', startDate, endDate);
        end
    end
end
