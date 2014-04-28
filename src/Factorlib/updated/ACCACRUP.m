classdef ACCACRUP < ACCACRU_Base
    %ACCACRUP Discretionary Component on Accrual Accounts Payable
    %
    %  See ACCACRU_Base for a detailed explanation.
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:03

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            factorTS = build@ACCACRU_Base(o, secIds, startDate, endDate, 'D000685855');
        end
    end
end
