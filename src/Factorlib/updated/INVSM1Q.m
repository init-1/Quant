classdef INVSM1Q < FacBase
    %INVSM1Q <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:09
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            %% Load data here (Loadxxx())
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            Qtrs = 5;
            Inv = o.loadItem(secIds,'D000679620',sDate,endDate,Qtrs);
            Sales = o.loadItem(secIds,'D000686629',sDate,endDate,Qtrs);
            
            %% Resample data here (aligndate())
            Inv_Avg = ftsnanmean(Inv{1:4});
            Sales_Sum = ftsnanmean(Sales{1:4})*4;
            Inv_Avg_Lag = ftsnanmean(Inv{2:5});
            Sales_Sum_Lag = ftsnanmean(Sales{2:5})*4;
            
            nbf = o.DCF('3M');
            Inv_Avg = backfill(Inv_Avg,nbf,'entry');
            Sales_Sum = backfill(Sales_Sum,nbf,'entry');
            Inv_Avg_Lag = backfill(Inv_Avg_Lag,nbf,'entry');
            Sales_Sum_Lag = backfill(Sales_Sum_Lag,nbf,'entry');
            
            %% Calculation here USUALLY
            factorTS = (Inv_Avg./Sales_Sum)./(Inv_Avg_Lag./Sales_Sum_Lag);
        end
    end
end
