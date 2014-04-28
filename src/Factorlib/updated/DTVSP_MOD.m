classdef DTVSP_MOD < FacBase
    %DTVSP_MOD <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:07

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            Debt_LT = o.loadItem(secIds,'D000679633',sDate,endDate,4);
            Debt_Cur = o.loadItem(secIds,'D000679594',sDate,endDate,4);
            Income_BD = o.loadItem(secIds,'D000679559',sDate,endDate,4); % operating income before depreciation
%             Dep = o.loadItem(secIds,'D000685797',sDate,endDate,4);
            Dep = o.loadItem(secIds,'D000686264',sDate,endDate,4);
            Income_Nop = o.loadItem(secIds,'D000685879',sDate,endDate,4);
            
            %% PIT calculation
            Debt_LT_Avg = ftsnanmean(Debt_LT{1:4});
            Debt_Cur_Avg = ftsnanmean(Debt_Cur{1:4});
            Income_BD_Sum = ftsnanmean(Income_BD{1:4}).*4;
            Dep_Sum = ftsnanmean(Dep{1:4}).*4;
            Income_Nop_Sum = ftsnanmean(Income_Nop{1:4}).*4;
            
            Income_AD_Sum = Income_BD_Sum - Dep_Sum;
            
            %% backfill the data
            nbf = o.DCF('2M');
            Debt_LT_Avg = backfill(Debt_LT_Avg,nbf,'entry');
            Debt_Cur_Avg = backfill(Debt_Cur_Avg,nbf,'entry');
            Income_AD_Sum = backfill(Income_AD_Sum,nbf,'entry');
            Income_Nop_Sum = backfill(Income_Nop_Sum,nbf,'entry');
            
            %% Calculation here USUALLY
            factorTS = ftsnansum(Debt_LT_Avg, Debt_Cur_Avg)./ftsnansum(Income_AD_Sum, Income_Nop_Sum);
        end
    end
end
