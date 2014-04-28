classdef GE_BOOK_PRICE < GlobalEnhanced
    %GE_BOOK_PRICE <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            if o.isLive
                BV = o.loadItem(secIds, 'D000110018', startDate, endDate);
                PR = o.loadItem(secIds, 'D000110013', startDate, endDate);
            else
                BV = o.loadItem(secIds, 'D000110113', startDate, endDate);
                PR = o.loadItem(secIds, 'D000112587', startDate, endDate);
            end
            factorTS=BV./PR;
        end
    end
end
