classdef GE_SALES_PRICE < GlobalEnhanced
    %GE_SALES_PRICE <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:26

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            SP = o.loadItem(secIds, 'D000111048', startDate, endDate);
            factorTS = 1./SP;
        end
    end
end
