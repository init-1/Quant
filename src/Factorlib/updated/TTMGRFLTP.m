classdef TTMGRFLTP < FacBase
    %TTMGRFLTP <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:16
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            
            closePrice = o.loadItem(secIds,'D001410415',sDate,endDate);
            shares = o.loadItem(secIds,'D001410472',sDate,endDate);
            NI = o.loadItem(secIds,'D000686576',sDate,endDate,4);
            RnD = o.loadItem(secIds,'D000686681',sDate,endDate,4);
            
            NI_Sum = ftsnanmean(NI{1:4})*4;
            RnD_Sum = ftsnanmean(RnD{1:4})*4;
            
            nbf = o.DCF('2M');
            NI_Sum = backfill(NI_Sum, nbf, 'entry');
            RnD_Sum = backfill(RnD_Sum, nbf, 'entry');
            
            %% Calculation here USUALLY
            factorTS = ftsnansum(NI_Sum, RnD_Sum)./(closePrice.*shares./1000000);
        end
    end
end
