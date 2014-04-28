classdef CAPEX2SAL_V2 < FacBase
    %CAPEX2SAL_V2 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:04
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(addtodate(datenum(startDate),-3,'M'),'yyyy-mm-dd');
            capexItem = 'D000686214';
            salesItem = 'D000686629';
            capex = o.loadItem(secIds, capexItem, sDate, endDate, 4);
            sales = o.loadItem(secIds, salesItem, sDate, endDate, 4);
            
            %% Data processing (backfill())
            % capex = CashFlowDecompPIT(capex,fq);
            capexSum = ftsnanmean(capex{1:4})*4;
            salesSum = ftsnanmean(sales{1:4})*4;
            capexSum = fill(capexSum, Inf, 'entry');
            salesSum = fill(salesSum, Inf, 'entry');
            
            %% Calculation here USUALLY
            factorTS = capexSum./salesSum;
            
        end
        
    end
end
