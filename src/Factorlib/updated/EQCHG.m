classdef EQCHG < FacBase
    %EQCHG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:08
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            %% Load data here (Loadxxx())
            sDate = datestr(addtodate(datenum(startDate),-5,'Y'),'yyyy-mm-dd');
            equityItem = 'D000110365';
            equity = o.loadItem(secIds, equityItem, sDate, endDate);
            equity = backfill(equity, o.DCF('18M'), 'entry');
            
            %% Calculation here USUALLY
            factorTS = equity ./ o.lagfts(equity, '36M', NaN) - 1;
            factorTS = fill(factorTS, Inf, 'entry');
        end
    end
end
