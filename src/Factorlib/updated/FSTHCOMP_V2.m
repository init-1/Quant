classdef FSTHCOMP_V2 < FacBase
    %FSTHCOMP_V2 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:09
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate_Sh = datestr(addtodate(datenum(startDate),-15,'M'),'yyyy-mm-dd'); % financial
            sDate_FS = datestr(addtodate(datenum(startDate),-3,'M'),'yyyy-mm-dd'); % financial statement item start retrieving Date
            
            % Retrieve data from DB
            shares = o.loadItem(secIds,'D001410472',sDate_Sh,endDate);

            Qtrs = 8;
            NI_BE = o.loadItem(secIds,'D000679557',sDate_FS,endDate,Qtrs);
            CFO = o.loadItem(secIds,'D000679450',sDate_FS,endDate,Qtrs);
            %%FQTR = o.loadItem(secIds,'D000647426',sDate_FS,endDate,Qtrs);
            TotAsset = o.loadItem(secIds,'D000686130',sDate_FS,endDate,Qtrs);
            CurAsset = o.loadItem(secIds,'D000686131',sDate_FS,endDate,Qtrs);
            CurLiab = o.loadItem(secIds,'D000686132',sDate_FS,endDate,Qtrs);
            Revenue = o.loadItem(secIds,'D000686629',sDate_FS,endDate,Qtrs);
            NI = o.loadItem(secIds,'D000686576',sDate_FS,endDate,Qtrs);
            LtDebt = o.loadItem(secIds,'D000679633',sDate_FS,endDate,Qtrs);
            
            % calculate the rolling 4Q (or 12M) sum of items from income / cash flow statement
            NI_BE_Sum = ftsnanmean(NI_BE{1:4})*4;
            CFO_Sum = ftsnanmean(CFO{1:4})*4;
            Revenue_Sum = ftsnanmean(Revenue{1:4})*4;
            NI_Sum = ftsnanmean(NI{1:4})*4;
            
            % calculate the rolling 4Q average of items from balance sheet
            TA_Avg = ftsnanmean(TotAsset{1:4});
            CA_Avg = ftsnanmean(CurAsset{1:4});
            CL_Avg = ftsnanmean(CurLiab{1:4});
            LD_Avg = ftsnanmean(LtDebt{1:4});
            
            % calculate the lagged 1Y items
            NI_BE_Sum_Lag = ftsnanmean(NI_BE{5:8})*4;
            Revenue_Sum_Lag = ftsnanmean(Revenue{5:8})*4;
            NI_Sum_Lag = ftsnanmean(NI{5:8})*4;
            TA_Avg_Lag = ftsnanmean(TotAsset{5:8});
            CA_Avg_Lag = ftsnanmean(CurAsset{5:8});
            CL_Avg_Lag = ftsnanmean(CurLiab{5:8});
            LD_Avg_Lag = ftsnanmean(LtDebt{5:8});
            
            nbf = o.DCF('3M'); 
            CFO_Sum = backfill(CFO_Sum, nbf, 'entry');
            NI_BE_Sum = backfill(NI_BE_Sum, nbf, 'entry');
            Revenue_Sum = backfill(Revenue_Sum, nbf, 'entry');
            NI_Sum = backfill(NI_Sum, nbf, 'entry');
            TA_Avg = backfill(TA_Avg, nbf, 'entry');
            CA_Avg = backfill(CA_Avg, nbf, 'entry');
            CL_Avg = backfill(CL_Avg, nbf, 'entry');
            LD_Avg = backfill(LD_Avg, nbf, 'entry');
            NI_BE_Sum_Lag = backfill(NI_BE_Sum_Lag, nbf, 'entry');
            Revenue_Sum_Lag = backfill(Revenue_Sum_Lag, nbf, 'entry');
            NI_Sum_Lag = backfill(NI_Sum_Lag, nbf, 'entry');
            TA_Avg_Lag = backfill(TA_Avg_Lag, nbf, 'entry');
            CA_Avg_Lag = backfill(CA_Avg_Lag, nbf, 'entry');
            CL_Avg_Lag = backfill(CL_Avg_Lag, nbf, 'entry');
            LD_Avg_Lag = backfill(LD_Avg_Lag, nbf, 'entry');
            
            %% Calculation here USUALLY
            ROA = NI_BE_Sum./TA_Avg;
            ROA_Lag = NI_BE_Sum_Lag./TA_Avg_Lag;
            CFOA = CFO_Sum./TA_Avg;
            Accrual = CFOA - ROA;
            Leverage = LD_Avg./TA_Avg;
            Leverage_Lag = LD_Avg_Lag./TA_Avg_Lag;
            Liquidity = CA_Avg./CL_Avg;
            Liquidity_Lag = CA_Avg_Lag./CL_Avg_Lag;
            Margin = NI_Sum./Revenue_Sum;
            Margin_Lag = NI_Sum_Lag./Revenue_Sum_Lag;
            Turnover = Revenue_Sum./TA_Avg;
            Turnover_Lag = Revenue_Sum_Lag./TA_Avg_Lag;
            
            ROA_Delta = ROA - ROA_Lag;
            Leverage_Delta = Leverage - Leverage_Lag;
            Liquidity_Delta = Liquidity - Liquidity_Lag;
            Margin_Delta = Margin - Margin_Lag;
            Turnover_Delta = Turnover - Turnover_Lag;
            EquityOffer_Delta = shares./o.lagfts(shares, '12M', NaN)-1; % shares are monthly here
            EquityOffer_Delta = aligndates(EquityOffer_Delta, ROA.dates);

            factorTS = ftsnansum(ROA>0, CFOA>0, Accrual>0, ROA_Delta>0, Leverage_Delta<0, Liquidity_Delta>0, Margin_Delta>0, Turnover_Delta>0, EquityOffer_Delta<0.01);
        end
    end
end
