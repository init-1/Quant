classdef DD < FacBase
    %DD Distance to Default
    %
    %  Formula:
    %    {Distance to Default} = \frac{1}{\sigma_{asset}} log(V/LD) = 1/\sigma_{asset} log((S+LD)/LD)
    %  where
    %    D = {Debt per Share}
    %    S = {Stock Price}
    %    L = {Average recovery rate on debt}
    %    V = {Market Value} = {Enterprice Value with Debt} (Total Debt×Recovery Rate)=S+LD
    %    \sigma_{asset} = {Volatility of Asset Value}
    %  Further, based on observed global debt recovery rate,
    %    L = 0.5
    %  Also, asset value volatility is assumed to follow underlying equity volatility 
    %  and is proportional to market capitalization and market value
    %    \sigma_{asset} = \sigma_{daily stock return over 1000 days} * S/(S+LD)×\sqrt(250)
    %  Lastly, 
    %    {Debt per Share} = {Financial Debt} - k_{mi} * {Minority Interest}
    %                     = {ST Debt}+{LT Debt} + k_{ol}×({Other ST Liabilities}+{Other LT Liabilities})
    %                       - k_{mi} * {Minority Interest}
    %  where
    %    k_{ol} = {Discount factor on other liabilities} = 0.5
    %    k_{mi} = {Subsidiary Debt-to-Equity Ratio and is set as 1}
    %
    %  All income statement items are annualized by summing up last four quarter values
    %  All balance sheet items are averaged on last four quarter values
    %
    %  Description:
    %    Distance to default is based on Creditgrades Technical Document
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:06

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('D');  % FORCE to be Daily Basis
            sigma_window = 1000;      % Volatility window, daily
            recoveryRate = 0.5;
            discountFactor = 0.5;
            subDebt2EquityRatio = 1;
            
            %%% Load PIT data
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            debt_lt  = o.loadItem(secIds, 'D000679633', sDate, endDate, 4);
            debt_cur = o.loadItem(secIds, 'D000679594', sDate, endDate, 4);
            otherLiab_lt  = o.loadItem(secIds, 'D000685974', sDate, endDate, 4);
            otherLiab_cur = o.loadItem(secIds, 'D000685954', sDate, endDate, 4);
            minor_int = o.loadItem(secIds, 'D000679644', sDate, endDate, 4);
            
            %% Load TS data
            sDate = datestr(datenum(startDate)-1.5*sigma_window, 'yyyy-mm-dd'); % scaled to account non-busday
            price  = o.loadItem(secIds, 'D001410415', sDate, endDate);  % should be daily
            nShare = o.loadItem(secIds, 'D001410472', startDate, endDate);
            
            return_daily = Price2Return(price, 1);  % daily returns
            sigma = ftsmovstd(return_daily, sigma_window, true);
            
            %% Components in formula
            debt_lt = ftsnanmean(debt_lt{1:4});
            debt_cur = ftsnanmean(debt_cur{1:4});
            otherLiab_lt = ftsnanmean(otherLiab_lt{1:4});
            otherLiab_cur = ftsnanmean(otherLiab_cur{1:4});
            minor_int = ftsnanmean(minor_int{1:4});
            
            nbf = o.DCF('6M');
            bc = cellfun(@(x){backfill(x,nbf,'entry')}, {debt_lt,debt_cur,otherLiab_lt,otherLiab_cur,minor_int});
            [debt_lt,debt_cur,otherLiab_lt,otherLiab_cur,minor_int] = bc{:};
            debt = debt_lt + debt_cur + discountFactor .* (otherLiab_lt + otherLiab_cur)- subDebt2EquityRatio .* minor_int;
            
            [debt, nShare, price, sigma] = aligndata(debt, nShare, price, sigma);  % maybe time-costing
            
            debt = debt*1000000 ./ nShare; % the PIT fundamental data are in the unit of 1 mil
            debt(debt < 0) = nan;
            
            sigma = sigma .* price ./ (price + recoveryRate * debt) * sqrt(o.DCF('A')); % annulized sigma
            factorTS = log(price ./ (recoveryRate .* debt) + 1) ./ sigma;
        end
    end
end
