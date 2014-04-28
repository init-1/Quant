classdef CAPEX2DEP_V2 < FacBase
    %CAPEX2DEP_V2 <a full descriptive name placed here>
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
            depItem = 'D000685797';
            capex = o.loadItem(secIds, capexItem, sDate, endDate, 4);
            dep = o.loadItem(secIds, depItem, sDate, endDate, 4);
            
            %% Data processing (backfill())
            % capex = CashFlowDecompPIT(capex,fq);
            capexSum = ftsnanmean(capex{1:4})*4;
            depSum = ftsnanmean(dep{1:4})*4;
            capexSum = backfill(capexSum, o.DCF('3M'), 'entry');
            depSum = backfill(depSum, o.DCF('3M'), 'entry');
            
            %% Calculation here USUALLY
            factorTS = capexSum./depSum;
        end
    end
end
