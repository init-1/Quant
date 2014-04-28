classdef GE_GrossMargin < GlobalEnhanced
    %GE_GrossMargin <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            GM = o.loadItem(secIds, 'D000111361', startDate, endDate);
            factorTS = backfill(GM, o.DCF('2M'), 'entry');
        end
    end
end
