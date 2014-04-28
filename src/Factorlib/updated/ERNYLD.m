classdef ERNYLD < FacBase
    %ERNYLD <a full descriptive name placed here>
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
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            
            shares = o.loadItem(secIds,'D001410472',sDate,endDate);
            closePrice = o.loadItem(secIds,'D001410415',sDate,endDate);
            EPS = o.loadItem(secIds,'D000685786',sDate,endDate,4);
            Equity = o.loadItem(secIds,'D000686133',sDate,endDate,4);
            
            EPS_Sum = ftsnanmean(EPS{1:4})*4;
            Equity_Avg = ftsnanmean(Equity{1:4});
            
            nbf = o.DCF('3M');
            EPS_Sum = backfill(EPS_Sum,nbf,'entry');
            Equity_Avg = backfill(Equity_Avg,nbf,'entry');
            
            %% Calculation here USUALLY
            factorTS = EPS_Sum./closePrice;
            adjustedEY = closePrice.*EPS_Sum./((Equity_Avg*1000000./shares).^2);
            factorTS(EPS_Sum<0) = adjustedEY(EPS_Sum<0);
        end
    end
end
