classdef CAPEX2DEP < FacBase
    %CAPEX2DEP <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:04

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            %% Load data here (Loadxxx())
            sDate = datestr(addtodate(datenum(startDate),-3,'M'),'yyyy-mm-dd');
            capexItem = 'D000686214';
            depItem = 'D000685797';
            %%fqItem = 'D000647426';
            capex = o.loadItem(secIds, capexItem, sDate, endDate, 5);
            dep = o.loadItem(secIds, depItem, sDate, endDate, 4);
            % fq = o.loadItem(secIds, fqItem, sDate, endDate, 5);
            
            %% Data processing (backfill())
            % capex = CashFlowDecompPIT(capex,fq);
            capexSum = ftsnansum(capex{:});
            depSum = ftsnansum(dep{:});
            capexSum = backfill(capexSum, o.DCF('3M'), 'entry');
            depSum = backfill(depSum, o.DCF('3M'), 'entry');
            
            %% Calculation here USUALLY
            factorTS = capexSum./depSum;
        end
    end
end
