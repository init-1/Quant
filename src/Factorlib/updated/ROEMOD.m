classdef ROEMOD < ROE_Base
    %ROEMOD <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:12
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sdate = datestr(datenum(startDate)-400, 'yyyy-mm-dd');
            cashflow = o.loadItem(secIds, 'D000679450', sdate, endDate, 5);
            capexp   = o.loadItem(secIds, 'D000686214', sdate, endDate, 5);
            cashdiv  = o.loadItem(secIds, 'D000679514', sdate, endDate, 5);
            % finqtr   = o.loadItem(secIds, 'D000647426', sdate, endDate, 5);
            
            % cashflow = CashFlowDecompPIT(cashflow, finqtr);
            % capexp   = CashFlowDecompPIT(capexp, finqtr);
            % cashdiv  = CashFlowDecompPIT(cashdiv, finqtr);
            
            free_cashflow = cell(1,4);
            for i = 1:4
                cashdiv{i} = abs(cashdiv{i});
                free_cashflow{i} = cashflow{i} - capexp{i} - cashdiv{i};
            end
            
            factorTS = build@ROE_Base(o, secIds, startDate, endDate, free_cashflow);
        end
    end
end
