classdef ACCACRUI < ACCACRU_Base
    %ACCACRUI Discretionary Component on Accrual Inventory
    %
    %  See ACCACRU_Base for a detailed explanation.
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:03

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            factorTS = build@ACCACRU_Base(o, secIds, startDate, endDate, 'D000679620');
        end
    end
end
