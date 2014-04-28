classdef ACCACRUR < ACCACRU_Base
    %ACCACRUR Discretionary Component on Accrual Accounts Receivable
    %
    %  See ACCACRU_Base for a detaled explanation.
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:03

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            factorTS = build@ACCACRU_Base(o, secIds, startDate, endDate, 'D000686144');
        end
    end
end
