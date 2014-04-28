classdef FacBase < myfints
    properties (SetAccess = protected)
        id = 0;
        name = '';
        type = 0;
        higherTheBetter = true;
        dateBasis = DateBasis('BD');
        isLive
        % Don't forget a member 'freq' derived from myfints
    end
    
    methods
        function o = create(o, isLive, varargin)
            % Usage:
            %  when isLive is true
            %     factor_object = create(factor_object, isLive, ids, runDate, 'name', val,...)
            %  or when isLive is false
            %     factor_object = create(factor_object, isLive, freq, ids, startDate, endDate, 'name', val,...)
            %  or to use a myfints as a factor
            %     factor_object = create(factor_object, myfints_obj, 'name', val,...)
            %
            if isa(isLive, 'myfints')  % First usage, ids actually is already myfints obj
                fts = isLive;
                o.freq = o.dateBasis.freqBasis;  % dummy here
            else    % Second usage, construct a myfints first
                if isa(varargin{end}, 'DateBasis')
                    o.dateBasis = varargin{end};
                    varargin(end) = [];
                end
                
                o.isLive = isLive;
                
                if isLive
                    FTSASSERT(~isempty(varargin), 'No enough arguments');
                    ids     = varargin{1};
                    runDate = varargin{2};
                    varargin(1:2) = [];
                    o.freq = o.dateBasis.freqBasis;  % dummy here
                    fts = o.buildLive(ids, runDate, varargin{:});
                    dates = datenum(runDate);
                else
                    FTSASSERT(length(varargin) > 3, 'No enough arguments');
                    o.freq    = varargin{1};
                    ids       = varargin{2};
                    startDate = varargin{3};
                    endDate   = varargin{4};
                    varargin(1:4) = [];  % now varargin contains additional parameters
                    fts = o.build(ids, startDate, endDate, varargin{:});
                    dates = o.genDates(startDate, endDate, o.freq);
                end
                
                fts = aligndates(fts, dates);
                s.type = '()'; s.subs = {isinf(fts)};
                fts = subsasgn(fts, s, NaN);   % equivelent to fts(isinf(fts)) = NaN
                fts.freq = o.freq;  % to make copy below correct
            end
            
            o = o.copy(fts);
            if ~isempty(varargin)  % if something still left in parameter list
                flds = {'id' 'name' 'type' 'higherTheBetter' 'isLive' 'dateBasis' 'desc'};
                pty  = Option.vararginOption(flds, varargin{:});
                for f = flds
                    if ~isempty(pty.(f{:}))
                        o.(f{:}) = pty.(f{:});
                    end
                end
            end
        end
        
        function val = subsref(obj, s)
            if strcmp(s(1).type,'.') && ismember(s(1).subs, properties(obj))
                val = obj.(s(1).subs);
                if length(s) > 1
                    val = subsref(val, s(2:end));
                end
                return;
            end
            val = subsref@myfints(obj, s);
        end
        
        function obj = subsasgn(obj, s, v)
            if strcmp(s(1).type,'.') && ismember(s(1).subs, properties(obj))
                FTSASSERT(length(s) == 1, 'Multiple-level reference in assignment of FacBase not allowed');
                obj.(s(1).subs) = v;
                return;
            end
            obj = subsasgn@myfints(obj, s, v);
        end
    end
    
    methods (Access = protected)
        function myfts = build(o, ids, startDate, endDate) %#ok<MANU,INUSD>
            myfts = [];
        end
        
        function myfts = buildLive(o, ids, runDate)
            myfts = o.build(ids, runDate, runDate);
        end
        
        function fts = loadItem(o, secIds, itemId, startDate, endDate, varargin)
            destfreq = o.dateBasis.freqBasis;  %%% or should it be o.freq???
            sDate = datestr(datenum(startDate)-12*31, 'yyyy-mm-dd');
            sql = runSP('QuantStrategy', ['select freq from datainterfaceserver.dataqa.api.itemmstr where id = ''' itemId ''''], {});
            if isnan(sql.freq)
                srcfreq = 'Y';
            else
                srcfreq = strtrim(sql.freq);
            end
            
            if srcfreq == 'B', srcfreq = 'D'; end
            if srcfreq == 'R', srcfreq = 'M'; end
            nfillperiod = ceil(1.1*o.DCF(srcfreq, destfreq));
            dates = o.genDates(sDate, endDate, destfreq);
            
            if strncmpi(itemId, 'D0006', 5) || strncmpi(itemId, 'D0020', 5)
                fts = LoadRawItemPIT2(secIds, itemId, sDate, endDate, varargin{:}); % varargin{1} should be number of quarters
                [fts{:}] = aligndates(fts{:}, dates);
                fts = cellfun(@(x){backfill(x, nfillperiod, 'entry')},fts);
                dates = o.genDates(startDate, endDate, destfreq);
                [fts{:}] = aligndates(fts{:}, dates);
            else
                fts = LoadRawItemTS(secIds, itemId, sDate, endDate, varargin{:});
                fts = aligndates(fts, dates);
                if ~o.isLive && strcmp(itemId(1:5), 'D0001') && ~ismember(itemId, {'D000112587', 'D000110013', 'D000110087'})
                    fts = o.lagfts(fts, '4M');
                end
                fts = backfill(fts, nfillperiod, 'entry');
                dates = o.genDates(startDate, endDate, destfreq);
                fts = aligndates(fts, dates);
            end
        end
        
        function by = loadBondYield(o, secIds, startDate, endDate)
        % Load bond yield data according o.freq
            dates = o.genDates(startDate, endDate, o.freq);
            
            seclist = sprintf('E%s,', secIds{:});
            BY = [];
            for cur = dates'
                BY = [BY runSP('QuantStrategy','[glb].[Global_Get_LatestBondYield]',{seclist,datestr(cur,'yyyy-mm-dd'),'D',1},'')]; %#ok<AGROW>
            end
            
            dates_ = [BY(:).DataDate];
            values = [BY(:).TargetVal];
            secids = [BY(:).SecId];
            
            dates_ = dates_(:);
            values = values(:);
            secids = secids(:);
            idx = cellfun(@(x)ischar(x),dates_);
            by = mat2xts(datenum(dates_(idx)), values(idx), secids(idx));
            by = padfield(by, secIds);
            dates = o.genDates(startDate, endDate, o.dateBasis.freqBasis);
            by = aligndates(by, dates);
        end
    end
    
    methods
        % Delegated functions
        function dates = genDates(o, startDate, endDate, freq)
            dates = o.dateBasis.genDates(startDate, endDate, freq);
        end
        
        function factor = DCF(o, targetfreq, srcfreq)
            if nargin < 3, srcfreq = o.dateBasis.freqBasis; end
            [n, targetfreq] = DateBasis.tenor(targetfreq);
            factor = round(o.dateBasis.cvtfactor(targetfreq, srcfreq)*n);
        end
        
        function fts = lagfts(o, fts, period, fillingStuff)
            if nargin < 4, fillingStuff = NaN; end
            if ischar(period) % period is form of '3M', '4W'
                nperiod = o.DCF(period);
            else
                nperiod = period;
            end
            
            if nperiod < 0
                fts = o.leadfts(fts, period, fillingStuff);
            elseif nperiod > 0
                fts = lagts(fts, nperiod, fillingStuff);
            end
        end
        
        function fts = leadfts(o, fts, period, fillingStuff)
            if nargin < 4, fillingStuff = NaN; end
            if ischar(period) % period is form of '3M', '4W'
                nperiod = o.DCF(period);
            else
                nperiod = period;
            end
            
            if nperiod < 0
                fts = o.lagfts(fts, period, fillingStuff);
            elseif nperiod > 0
                fts = leadts(fts, nperiod, fillingStuff);
            end
        end
    end
end

% D000110113 BOOK VALUE PER SHARE
% D000110115 COMMON SHARES OUTSTANDING
% D000110142 CASH FLOW PER SHARE - FISCAL YEAR END
% D000110146 DIVIDENDS PER SHARE
% D000110162 DIVIDENDS PER SHARE - FISCAL
% D000110193 EARNINGS PER SHARE
% D000110211 EARNINGS PER SHARE - FISCAL YEAR END
% D000110440 DIVIDEND PAYOUT (% EARNINGS) - TOTAL DOLLAR
% D000110442 DIVIDEND PAYOUT PER SHARE
% D000111154 RETURN ON EQUITY - PER SHARE
% D000111158 RETURN ON INVESTED CAPITAL
% D000111193 TOTAL ASSETS
% D000415172 Mean
% D000415179 FQ1 Forecast Period End Date
% D000415183 FY1 Forecast Period End Date
% D000415184 FY2 Forecast Period End Date
% D000415185 FY3 Forecast Period End Date
% D000431932 FQ0 Period End Date
% D000431933 FY0 Period End Date
% D000432130 EPS Actual Annual - Intl USD
% D000432131 EPS Actual Qtrly - Intl USD
% D000435580 FQ1 EPS Consensus Mean - Intl USD
% D000435584 FY1 EPS Consensus Mean - Intl USD
% D000435585 FY2 EPS Consensus Mean - Intl USD
% D000435586 FY3 EPS Consensus Mean - Intl USD
% D000435589 Long Term EPS Consensus Mean - Intl USD
% D000435594 FY1 EPS Consensus Median - Intl USD
% D000435595 FY2 EPS Consensus Median - Intl USD
% D000435596 FY3 EPS Consensus Median - Intl USD
% D000435604 FY1 EPS Consensus NumDown - Intl USD
% D000435605 FY2 EPS Consensus NumDown - Intl USD
% D000435614 FY1 EPS Consensus NumEst - Intl USD
% D000435615 FY2 EPS Consensus NumEst - Intl USD
% D000435624 FY1 EPS Consensus NumUp - Intl USD
% D000435625 FY2 EPS Consensus NumUp - Intl USD
% D000435634 FY1 EPS Consensus StdDev - Intl USD
% D000437351 DPS QFS Actual Ann. - Intl USD
% D000448965 EPS QFS Mean FY1 - Intl USD
% D000448966 EPS QFS Mean FY2 - Intl USD
% D000448967 EPS QFS Mean FY3 - Intl USD
% D000448970 EPS QFS Mean Long Term - Intl USD
% D000449005 EPS QFS Median FY1 - Intl USD
% D000449135 EPS QFS StdDev FY1 - Intl USD
% D000647426 FQN
% D000679449 Cash from Investing [2005] - QTR - USD
% D000679450 Cash from Operations [2006] - QTR - USD
% D000679514 Common & Preferred Stock Dividends Paid [2022] - QTR - USD
% D000679524 Unlevered Free Cash Flow [4423] - QTR - USD
% D000679525 Change In Net Working Capital [4421] - QTR - USD
% D000679555 Dividend Per Share [3058] - QTR - USD
% D000679557 Earnings From Continuing Operations [7] - QTR - USD
% D000679558 EBIT [400] - QTR - USD
% D000679559 EBITDA [4051] - QTR - USD
% D000679586 Total Cash And Short Term Investments [1002] - QTR - USD
% D000679594 Current Portion of Long Term Debt/Capital Leases [1279] - QTR - USD
% D000679620 Inventory [1043] - QTR - USD
% D000679633 Long Term Debt [1049] - QTR - USD
% D000679644 Minority Interest [1052] - QTR - USD
% D000685786 Net EPS - Basic [9] - QTR - USD
% D000685790 Cost Of Revenues [1] - QTR - USD
% D000685797 Depreciation & Amortization, Total [2] - QTR - USD
% D000685855 Accounts Payable [1018] - QTR - USD
% D000685879 Interest And Investment Income [65] - QTR - USD
% D000686130 Total Assets [1007] - QTR - USD
% D000686131 Total Current Assets [1008] - QTR - USD
% D000686132 Total Current Liabilities [1009] - QTR - USD
% D000686133 Total Common Equity [1006] - QTR - USD
% D000686136 Total Equity [1275] - QTR - USD
% D000686138 Total Liabilities [1276] - QTR - USD
% D000686144 Total Receivables [1001] - QTR - USD
% D000686214 Capital Expenditure [2021] - QTR - USD
% D000686576 Net Income to Common Incl Extra Items [16] - QTR - USD
% D000686584 Short Term Debt Issued [2043] - QTR - USD
% D000686629 Total Revenues [28] - QTR - USD
% D000686681 R & D Expenses [100] - QTR - USD
% D000902552 LTQ - Liabilities - Total - INDL - Q54 - NA
% D000902560 NIQ - Net Income (Loss) - INDL - Q69 - NA
% D000902743 XRDQ - Research and Development Expense - INDL - Q4 - NA
% D000904772 ACTQ - Current Assets - Total - INDL - Q40 - G/NA
% D000904775 APQ - Account Payable/Creditors - Trade - INDL - Q46 - G/NA
% D000904776 ATQ - Assets - Total - INDL - Q44 - G/NA
% D000904778 CEQQ - Common/Ordinary Equity - Total - INDL - Q59 - G/NA
% D000904779 CHEQ - Cash and Short-Term Investments - INDL - Q36 - G/NA
% D000904780 COGSQ - Cost of Goods Sold - INDL - Q30 - G/NA
% D000904782 DLCQ - Debt in Current Liabilities - INDL - Q45 - G/NA
% D000904783 DLTTQ - Long-Term Debt - Total - INDL - Q51 - G/NA
% D000904788 IBQ - Income Before Extraordinary Items - INDL - Q8 - G/NA
% D000904790 INVTQ - Inventories - Total - INDL - Q38 - G/NA
% D000904793 LCOQ - Current Liabilities - Other - Total - INDL - Q48 - G/NA
% D000904794 LCTQ - Current Liabilities - Total - INDL - Q49 - G/NA
% D000904796 LOQ - Liabilities - Other - INDL - Q50 - G/NA
% D000904799 MIBQ - Minority Interest - Balance Sheet - INDL - Q53 - G/NA
% D000904801 NOPIQ - Non-Operating Income (Expense) - Total - INDL - Q31 - G/NA
% D000904802 OIADPQ - Operating Income After Depreciation - Quarterly - INDL - G/NA
% D000904803 OIBDPQ - Operating Income Before Depreciation - Quarterly - INDL - Q21 - G/NA
% D000904808 RECTQ - Receivables - Total - INDL - Q37 - G/NA
% D000904812 SALEQ - Sales/Turnover (Net) - INDL - Q2 - G/NA
% D000904813 SEQQ - Shareholders Equity - Total - INDL - Q60 - G/NA
% D000904876 CAPXY - Capital Expenditures - INDL - Q90 - G/NA
% D000904884 DVY - Cash Dividends - INDL - Q89 - G/NA
% D000904899 IVNCFY - Investing Activities - Net Cash Flow - INDL - Q111 - G/NA
% D000904903 OANCFY - Operating Activities - Net Cash Flow - INDL - Q108 - G/NA
% D000905027 FQTR - Fiscal Quarter
% D000905054 DVPSXQ - Div per Share - Exdate - Quarter - Q16
% D001400028 Price Index
% D001410414 Close - Local
% D001410415 Close - USD
% D001410419 High - USD
% D001410423 Low - USD
% D001410430 Volume - Local
% D000904558 EMP - Employees - INDL - A29 - G/NA
% D000902872 NIQ - Net Income (Loss) - INDL - Q69 - NA - USD
% D000902495 EPSPXQ - Earnings Per Share (Basic) - Excluding Extraordinary Items - INDL - Q19 - NA
% D000902482 DPQ - Depreciation and Amortization - Total - INDL - Q5 - NA
% D000686264 Depreciation & Amortization [2171] - QTR - USD
% D000685974 Other Liabilities, Total [1282] - QTR - USD
% D000685954 Other Current Liabilities, Total [1269] - QTR - USD
% D000446805 DPS QFS Mean FY1 - Intl USD
% D000437545 SAL QFS Actual Ann. - Intl USD
% D000437417 EPS QFS Actual Ann. - Intl USD
% D000437319 BPS QFS Actual Ann. - Intl USD
% D000436864 FY1 SAL Consensus Mean - Intl USD
% D000434985 FY2 DPS Consensus NumUp - Intl USD
% D000434984 FY1 DPS Consensus NumUp - Intl USD
% D000434975 FY2 DPS Consensus NumEst - Intl USD
% D000434974 FY1 DPS Consensus NumEst - Intl USD
% D000434965 FY2 DPS Consensus NumDown - Intl USD
% D000434964 FY1 DPS Consensus NumDown - Intl USD
% D000434945 FY2 DPS Consensus Mean - Intl USD
% D000434944 FY1 DPS Consensus Mean - Intl USD
% D000434825 FY2 CPS Consensus NumUp - Intl USD
% D000434824 FY1 CPS Consensus NumUp - Intl USD
% D000434815 FY2 CPS Consensus NumEst - Intl USD
% D000434814 FY1 CPS Consensus NumEst - Intl USD
% D000434805 FY2 CPS Consensus NumDown - Intl USD
% D000434804 FY1 CPS Consensus NumDown - Intl USD
% D000434785 FY2 CPS Consensus Mean - Intl USD
% D000434784 FY1 CPS Consensus Mean - Intl USD
% D000434665 FY2 BPS Consensus NumUp - Intl USD
% D000434664 FY1 BPS Consensus NumUp - Intl USD
% D000434655 FY2 BPS Consensus NumEst - Intl USD
% D000434654 FY1 BPS Consensus NumEst - Intl USD
% D000434645 FY2 BPS Consensus NumDown - Intl USD
% D000434644 FY1 BPS Consensus NumDown - Intl USD
% D000434625 FY2 BPS Consensus Mean - Intl USD
% D000434624 FY1 BPS Consensus Mean - Intl USD
% D000432194 SAL Actual Annual - Intl USD
% D000432098 DPS Actual Annual - Intl USD
% D000432082 BPS Actual Annual - Intl USD
% D000432078 Price - Intl USD
% D000412646 FY3 SAL Consensus Median - Local
% D000412645 FY2 SAL Consensus Median - Local
% D000412644 FY1 SAL Consensus Median - Local
% D000411394 FY1 EPS Consensus NumUp - Local
% D000411384 FY1 EPS Consensus NumEst - Local
% D000411374 FY1 EPS Consensus NumDown - Local
% D000411369 Long Term EPS Consensus Median - Local
% D000411366 FY3 EPS Consensus Median - Local
% D000411365 FY2 EPS Consensus Median - Local
% D000411364 FY1 EPS Consensus Median - Local
% D000410726 FY3 DPS Consensus Median - Local
% D000410725 FY2 DPS Consensus Median - Local
% D000410724 FY1 DPS Consensus Median - Local
% D000410566 FY3 CPS Consensus Median - Local
% D000410565 FY2 CPS Consensus Median - Local
% D000410564 FY1 CPS Consensus Median - Local
% D000410406 FY3 BPS Consensus Median - Local
% D000410405 FY2 BPS Consensus Median - Local
% D000410404 FY1 BPS Consensus Median - Local
% D000410178 EPS Actual Annual - Local
% D000410146 DPS Actual Annual - Local
% D000410138 CPS Actual Annual - Local
% D000410126 Price - Local
% D000310017 Close - Local (IDC Obsolete - Redirect to Datastream D001410414)
% D000310006 TotRet (IDC Obsolete - Redirect to Datastream D001410446)
% D000210568 MSCI Index without dividends in local currency
% D000112644 COMMON SHARES OUTSTANDING
% D000112587 MARKET PRICE - WEEK CLOSE
% D000112408 TRAILING TWELVE MONTHS EBITDA
% D000112407 TRAILING TWELVE MONTHS EBIT
% D000111739 ENTERPRISE VALUE
% D000111726 TOTAL DEBT % COMMON EQUITY
% D000111623 TRAILING TWELVE MONTHS CASH FLOW PER SHARE
% D000111622 TRAILING TWELVE MONTHS EARNINGS PER SHARE
% D000111513 NET SALES OR REVENUES
% D000111453 EARNINGS PER SHARE - FISCAL YEAR END
% D000111412 TOTAL ASSETS
% D000111361 TRAILING TWELVE MONTHS GROSS MARGIN
% D000111346 DIVIDEND YIELD - CLOSE
% D000111345 PRICE/BOOK VALUE RATIO - CLOSE
% D000111339 NET MARGIN
% D000111205 TOTAL DEBT % COMMON EQUITY
% D000111132 RESEARCH & DEVELOPMENT
% D000111048 PRICE/SALES
% D000111021 PRICE/BOOK VALUE RATIO - CLOSE
% D000110891 OPERATING INCOME - 5 YR ANNUAL GROWTH
% D000110852 NET SALES / REVENUES - 5 YR ANNUAL GROWTH
% D000110842 NET MARGIN
% D000110729 INVENTORY TURNOVER
% D000110585 FUNDS FROM OPERATIONS
% D000110578 FOREIGN SALES % TOTAL SALES
% D000110538 EXTERNAL FINANCING
% D000110514 ENTERPRISE VALUE
% D000110479 EARNINGS PER SHARE - 5 YR ANNUAL GROWTH
% D000110473 EARNINGS BEFORE INTEREST AND TAXES (EBIT)
% D000110467 DIVIDENDS PER SHARE - 5 YR ANNUAL GROWTH
% D000110466 DIVIDENDS PER SHARE - 3 YR ANNUAL GROWTH
% D000110365 COMMON EQUITY
% D000110343 CASH DIVIDENDS PAID - TOTAL
% D000110329 CAPITAL EXPENDITURES (ADDITIONS TO FIXED ASSETS)
% D000110237 FREE CASH FLOW PER SHARE
% D000110101 DIVIDEND YIELD - CURRENT
% D000110087 EARNINGS PER SHARE - LAST 12 MONTHS
% D000110018 BOOK VALUE PER SHARE - CURRENT
% D000110013 MARKET PRICE - CURRENT
% D000453775 Market Price Current - Local
% D000453774 Shares - Local
% D000800522 S&P Index - PRCCD - Index Price - Close Daily
% D000453285 SAL QFS Mean FY1 - Intl USD
% D001410431 Volume - USD
% D001410446 Return Index - Local
% D001410451 Market Cap - USD
% D001410472 Shares Oustanding  w/Fill-up
% D001500001 Barra US Equity Model - PredBeta
% D001500002 Barra US Equity Model - HistBeta
% D001700010 Interest Rate
% D002000016 EPSPXQ PIT - Earnings Per Share (Basic) - Excluding Extraordinary Items - Q19h
% D002201164 Short Interest
% D002201193 Short Interest (Historial) (direct to D000700160)
% D002400008 CFROI_Change
% D002400009 CFROI_Key_Momentum
% D002400010 PPCTB
% D002400017 CFROI_Used_in_Valuation
% D002400018 ValueCost_Ratio
% D002400019 WINDDOWN
% D002400028 INVGTH5Y
% D002400029 Growth_Rate_Asset_FY0
% D002400038 CFROI_Key_Momentum_Month_1
% D002400039 CFROI_Key_Momentum_Month_2
% D002400041 EPSSURP
% D002400047 Sales_Inflation_Adj_GI_FY0
% D002400051 CFROIFY0
% D002400054 Eq_FCF_Mult_FY2
% D002400080 Real_Growth_Infl_Adj_Grs_Inv_FY_1
% D002400081 Real_Growth_Infl_Adj_Grs_Inv_FY_2
% D002400087 CFROI_FY_1
% D002400088 CFROI_FY_2
% D002400100 Discount_Rate_FY0
% D002400101 Discount_Rate_FY_1
% D002400102 Discount_Rate_FY_2
% D002400104 Interest_Coverage_Ratio_FY0
% D002400107 Sustainable_Growth_FY0
% D002418002 Revision Score
% D002418003 Earnings Surprise Forecast
% D002418004 Earnings Quality
% D002420005 DP_FY0
% D002420006 DP_FY1
% D002420007 DP_FY2
% D002420012 EP_FY2
% D002420027 EBITDAEV_FY0
% D002420037 SALESP_FY1
% D002420038 SALESP_FY2
% D002420040 Shares_Buyback
% D002420042 Bret1
% D002420045 Bret9
% D002420049 Earnings_rev_F1
% D002420052 Sales_growth_1yr_reported
% D002420054 EPS_Revision
% D002420056 Dial_EP
% D002420059 ROE_FY2
% D002420060 Earnings_Surprise
% D002420061 Profit_Growth
% D002420063 Volume_momentum
% D002420064 CapexDep
% D002420066 ChangeWorkingCapitalAsset
% D002420084 ROA_FY1_FY0
% D003010002 Total Demand Quantity: (Total quantity of demand: Total quantity of borrowed/loaned securities net of double counting)
% D003010004 BO Inventory Quantity: (Beneficial Owner Inventory Quantity : Quantity of current inventory available from beneficial owners. For Record Type 2 this value is implied)
% D003010048 VWAF Score 7 Day: (Value Weighted Average Fee Score 7 days: Value Weighted Average Fee for all new trades over the most recent 7 calendar days expressed in undisclosed Fee buckets 0-5. 0 the cheapest to borrow and 5 the most expensive)
% D003010051 VWAF 30 Day Change: (Change to Value Weighted Average Fee Score 30 days: Change in the 30 day Fee average compared to yesterdays 30 day fee average, as a %)
% D003010052 VWAF Score 60 Day: (Value Weighted Average Fee Score 60 days: Value Weighted Average Fee for all new trades on the most recent 60 calendar days expressed in undisclosed Fee buckets 0-5. 0 the cheapest to borrow and 5 the most expensive)
% D003010054 VWAF Score All: (Value Weighted Average Fee Score all days: Value Weighted Average Fee for all open trades expressed in undisclosed Fee buckets 0-5. 0 the cheapest to borrow and 5 the most expensive)
% D003010057 Active BO Inventory Quantity: (Gross realistically borrowable Beneficial Owner inventory)
% D003010059 Active Available BO Inventory Quantity: (Quantity of shares realistically available for borrowing by removing the Beneficial Owner On Loan Value from the Active Beneficial Owner Inventory Value)
% D003010061 Active Utilisation by Quantity: (Demand as a % of the realistically available supply (Beneficial Owner On Loan Quantity/ Active Beneficial Owner Inventory Quantity))
% D003010063 Utilisation by Quantity: (Utilisation calculated using quantity rather than value figures (Beneficial Owner On Loan Quantity/Beneficial Owner Inventory Quantity))
% D003010064 SAF: (Simple average fee of stock borrow transactions from Hedge Funds in this security)
% D003010065 SAR: (Simple average rebate of stock borrow transactions from Hedge Funds in this security)
% D003010066 DCBS: (Data Explorers Daily Cost of Borrow Score; a number from 1 to 10 indicating the rebate/fee charged by the Agent Lender (e.g. State Street) based on the 7 day weighted average cost, where 1 is cheapest and 10 is most expensive)


