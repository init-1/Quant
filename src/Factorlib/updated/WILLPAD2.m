classdef WILLPAD2 < FacBase
    %WILLPAD2 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:16
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('BD');
            trendWindow = 260;
            alpha = 0.99;
            signalWindow = 19;
            
            sdate = datestr(datenum(startDate)-2*(trendWindow+signalWindow)/20*31, 'yyyy-mm-dd');
            price = o.loadItem(secIds, 'D001410415', sdate, endDate);   % daily data
            pr_low = o.loadItem(secIds, 'D001410423', sdate, endDate);  % daily data
            pr_high = o.loadItem(secIds, 'D001410419', sdate, endDate); % daily data
            
            [price, pr_low, pr_high] = aligndata(price, pr_low, pr_high);
            price_lag = o.lagfts(price, '1D');
            
            ad = price;
            ad(:,:) = 0;
            adup = price - biftsfun(price_lag, pr_low, @min);
            up   = price > price_lag;
            ad(up) = adup(up);
            addown = price - biftsfun(price_lag, pr_high, @max);
            down   = price < price_lag;
            ad(down) = addown(down);
            
            coef = alpha .^ (trendWindow:-1:1);
            ad(1:trendWindow,:) = bsxfun(@times, ad(1:trendWindow,:), coef');
            
            wad = ad;
            for t = trendWindow+1:size(ad,1)
                wad(t,:) = nansum(ad(t-trendWindow:t,:),1);
                ad(t-trendWindow:t,:) = ad(t-trendWindow:t,:) * alpha;
            end
            
            signal = price;
            signal(:,:) = 0;
            
            % Sell signal
            f = @(x) max(x, [], 1);
            wadmax = ftsmovfun(wad, trendWindow, f);
            pr_max = ftsmovfun(price, trendWindow, f);
            signal(fts2mat(pr_max == price) & fts2mat(wadmax ~= wad)) = -1;
            % Buy signal
            f = @(x) min(x, [], 1);
            wadmin = ftsmovfun(wad, trendWindow, f);
            pr_min = ftsmovfun(price, trendWindow, f);
            signal(fts2mat(pr_min == price) & fts2mat(wadmin ~= wad)) = 1;
            
            coef = alpha .^ (signalWindow:-1:1);
            factorTS = signal;
            signal(1:signalWindow,:) = bsxfun(@times, signal(1:signalWindow,:), coef');
            for t = signalWindow+1:size(factorTS,1)
                factorTS(t,:) = nansum(signal(t-signalWindow:t,:), 1);
                signal(t-signalWindow:t,:) = signal(t-signalWindow:t,:) * alpha;
            end
        end % of the function
    end
end
