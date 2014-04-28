classdef RESINCM < FacBase
    %RESINCM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:11
    
    properties (Constant)
        RiskPremium = 0.07;
        RiskFreeRate = 0.02;
        Persistence = 1;
    end
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            %% Generate dates as backtest dates and data in principle should be aligned against dates
            dates = o.genDates(startDate, endDate, o.freq);    % 'Busday', 0);
            
            sdate = datestr(datenum(startDate)-366*2, 'yyyy-mm-dd');
            
            if o.isLive  % Live version
                BPS = o.loadItem(secIds, 'D000437319', sdate, endDate);
                DPS = o.loadItem(secIds, 'D000437351', sdate, endDate);
                EPS = o.loadItem(secIds, 'D000437417', sdate, endDate);
                
                EPS_FY1 = o.loadItem(secIds, 'D000448965', sdate, endDate);
                EPS_FY2 = o.loadItem(secIds, 'D000448966', sdate, endDate);
                EPS_FY3 = o.loadItem(secIds, 'D000448967', sdate, endDate);
                EPS_LTG = o.loadItem(secIds, 'D000448970', sdate, endDate);
                
                %             Equity = Live2PIT(o.loadItem(secIds, 'D000904778', sdate, endDate, targetFreq));
                %             DPSQ = Live2PIT(o.loadItem(secIds, 'D000905054', sdate, endDate, targetFreq));
            else   % Backtest version
                BPS = o.loadItem(secIds, 'D000432082', sdate, endDate);
                if isempty(BPS) % if BPS retrieved from IBES is empty, go to worldscope to source the BPS
                    BPS = o.loadItem(secIds, 'D000110113', sdate, endDate);
                    BPS = backfill(BPS,inf,'entry');
                end
                DPS = o.loadItem(secIds, 'D000432098', sdate, endDate);
                if isempty(DPS) % if DPS retrieved from IBES is empty, go to worldscope to source the BPS
                    DPS = o.loadItem(secIds, 'D000110146', sdate, endDate);
                    DPS = backfill(DPS,inf,'entry');
                end
                EPS = o.loadItem(secIds, 'D000432130', sdate, endDate);
                
                EPS_FY1 = o.loadItem(secIds, 'D000435584', sdate, endDate);
                EPS_FY2 = o.loadItem(secIds, 'D000435585', sdate, endDate);
                EPS_FY3 = o.loadItem(secIds, 'D000435586', sdate, endDate);
                EPS_LTG = o.loadItem(secIds, 'D000435589', sdate, endDate);
            end
            
            Equity = o.loadItem(secIds, 'D000686133', sdate, endDate, 4);
            DPSQ   = o.loadItem(secIds, 'D000679555', sdate, endDate, 4);
            
            Equity = ftsnanmean(Equity{1:4});      % average of last 4 quarters
            DPSQ   = ftsnanmean(DPSQ{1:4}) * 4;    % summation of last 4 quarters
            
            PredBeta = o.loadItem(secIds, 'D001500001', sdate, endDate);
            PredBeta(isnan(fts2mat(PredBeta))) = 1;
            CostOfEquity = PredBeta .* RESINCM.RiskPremium + RESINCM.RiskFreeRate;
            
            Price  = o.loadItem(secIds, 'D001410415', sdate, endDate);
            Shares = o.loadItem(secIds, 'D001410472', sdate, endDate);
            
            [Price, Shares, BPS, DPS, EPS, EPS_FY1, EPS_FY2, EPS_FY3, EPS_LTG, Equity, DPSQ, CostOfEquity] = aligndates(Price, Shares, BPS, DPS, EPS, EPS_FY1, EPS_FY2, EPS_FY3, EPS_LTG, Equity, DPSQ, CostOfEquity, dates);
            
            bf_Period = 15;
            BPS = backfill(BPS, bf_Period, 'entry');
            DPS = backfill(DPS, bf_Period, 'entry');
            EPS = backfill(EPS, bf_Period, 'entry');
            EPS_FY1 = backfill(EPS_FY1, bf_Period, 'entry');
            EPS_FY2 = backfill(EPS_FY2, bf_Period, 'entry');
            EPS_FY3 = backfill(EPS_FY3, bf_Period, 'entry');
            EPS_LTG = backfill(EPS_LTG, bf_Period, 'entry');
            Equity = backfill(Equity, bf_Period, 'entry');
            DPSQ = backfill(DPSQ, bf_Period, 'entry');
            CostOfEquity = backfill(CostOfEquity, bf_Period, 'entry');
            
            DPS(isnan(fts2mat(DPS))) = DPSQ(isnan(fts2mat(DPS)));
            DivPO = DPS ./ EPS;
            DivPO(isnan(fts2mat(DivPO))) = 0;
            
            BV_0 = BPS;
            BV_0_Backup = 1000000*Equity./Shares;
            BV_0(isnan(fts2mat(BV_0))) = BV_0_Backup(isnan(fts2mat(BV_0)));
            
            BV_1 = BV_0 + EPS_FY1.*(1-DivPO);
            
            BV_2 = BV_1 + EPS_FY2.*(1-DivPO);
            
            BV_3 = BV_2 + EPS_FY3.*(1-DivPO);
            
            Value_FY1 = (EPS_FY1 - BV_0.*CostOfEquity)./(1+CostOfEquity);
            Value_FY2 = (EPS_FY2 - BV_1.*CostOfEquity)./((1+CostOfEquity).^2);
            Value_FY3 = (EPS_FY3 - BV_2.*CostOfEquity)./((1+CostOfEquity).^3);
            
            Value_FY1(isnan(fts2mat(Value_FY1))) = 0;
            Value_FY2(isnan(fts2mat(Value_FY2))) = 0;
            Value_FY3(isnan(fts2mat(Value_FY3))) = 0;
            
            IntValue_Residual = BV_0 + Value_FY1 + Value_FY2 + Value_FY3;
            IntValue_Residual(isnan(fts2mat(IntValue_Residual))) = 0;
            
            IntValue_Terminal = ((1+EPS_LTG./100).*EPS_FY3 - BV_3.*CostOfEquity)./ ((1 + CostOfEquity - RESINCM.Persistence).*((1 + CostOfEquity).^3));
            IntValue_Terminal(isnan(fts2mat(IntValue_Terminal))) = 0;
            
            factorTS = (IntValue_Residual + IntValue_Terminal)./Price;
        end
    end
end
