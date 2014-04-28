classdef DEFAULTPROB < FacBase
    %DEFAULTPROB <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:06

    methods (Access = protected)
        function [factorTS, priceDateStruct] = build(o, secIds, startDate, endDate)
            window_sigma = 252;      % Volatility window (business days in one year)
            sDate = datestr(datenum(startDate)-1.5*window_sigma-21, 'yyyy-mm-dd');
            dates = o.genDates(startDate, endDate, o.targetFreq);    % 'Busday', 0);
            
            %% Load data
            totalLiab = o.loadItem(secIds, 'D000686138', sDate, endDate, 1);
            price  = o.loadItem(secIds, 'D001410415', sDate, endDate);
            nShare = o.loadItem(secIds, 'D001410472', sDate, endDate);
            rfr = o.loadItem('FRTCM3M', 'D001700010', sDate, endDate);
            rfr = rfr./100; % the item in the DB is in percentage
            %% aligndata
            [price, nShare] = aligndata(price, nShare);
            price = backfill(price, 30, 'entry');
            nShare = backfill(nShare, 30, 'entry');
            
            equity = price.*nShare;
            return_equity = price./o.lagfts(price, '1M', nan) - 1; % daily return
            sigma_equity = ftsmovstd(return_equity, window_sigma, 1)*sqrt(252); % annualized daily equity volatility
            
            debt = ftsnanmean(totalLiab{:});
            debt = 1000000*debt; % the PIT fundamental data is in the unit of 1 mil
            
            [debt, equity, sigma_equity] = aligndata(debt, equity, sigma_equity, dates);
            rfr = aligndates(rfr, equity.dates);
            debt = backfill(debt, 4, 'entry');
            
            % deal with data exception
            debt(~(debt >= 0)) = NaN;
            equity(~(equity >= 0)) = NaN;
            sigma_equity(~(sigma_equity >= 0)) = NaN;
            rfr(~(rfr >= 0)) = NaN;
            
            %% calculation
            T = 1; % assumed horizon = 1 year
            
            % solve for asset value and its volatility for each factor calculation date
            value_asset = myfints(dates, nan(numel(dates), size(debt,2)), fieldnames(debt,1));
            sigma_asset = myfints(dates, nan(numel(dates), size(debt,2)), fieldnames(debt,1));
            return_asset = myfints(dates, nan(numel(dates), size(debt,2)), fieldnames(debt,1));
            exitflag1 = nan(numel(dates), size(debt,2));
            exitflag2 = nan(numel(dates), size(debt,2));
            
            for i = 1:numel(dates)
                [valueTemp, sigmaTemp, returnTemp, flag1, flag2] = o.SolveKMV(rfr(i,:), equity(i,:), debt(i,:), sigma_equity(i,:), T);
                value_asset(i,:) = fts2mat(valueTemp);
                sigma_asset(i,:) = fts2mat(sigmaTemp);
                return_asset(i,:) = fts2mat(returnTemp);
                exitflag1(i,:) = flag1;
                exitflag2(i,:) = flag2;
            end
            
            Dist2Default = (log(value_asset./debt) + (return_asset - 0.5*(sigma_asset.^2)).*T)./(sigma_asset.*sqrt(T));
            
            % calculate default probability from distance to default
            factorTS = myfints(Dist2Default.dates, cdf('Normal', -fts2mat(Dist2Default), 0, 1), fieldnames(Dist2Default,1));
            
            factorTS(isinf(fts2mat(factorTS))) = nan;
            if nargout > 1
                priceDateStruct = LatestDataDate(price);
            end
        end
        
        
        function [factorTS, priceDateStruct] = buildLive(o, secIds, endDate)
            [factorTS, priceDateStruct] = o.build(secIds, endDate, endDate, 'M');
        end
        
        
        function [value_asset, sigma_asset, rtn_asset, exitflag1, exitflag2] = SolveKMV(rfr, equity, debt, sigma_equity, T)
            nstock = size(equity,2);
            secid = fieldnames(sigma_equity,1);
            resultdate = sigma_equity.dates;
            value_asset = myfints(resultdate, nan(size(sigma_equity)), secid);
            sigma_asset = myfints(resultdate, nan(size(sigma_equity)), secid);
            rtn_asset = myfints(resultdate, nan(size(sigma_equity)), secid);
            exitflag1 = nan(size(sigma_equity));
            exitflag2 = nan(size(sigma_equity));
            
            rfr = fts2mat(rfr);
            equity = fts2mat(equity);
            debt = fts2mat(debt);
            sigma_equity = fts2mat(sigma_equity);
            
            for i = 1:nstock % loop for each stock
                if any(isnan([equity(i), debt(i), sigma_equity(i), rfr])) % if any of the necessary item is NaN
                    continue; % skip to the next stock, leave the current stock value to be nan;
                end
                sigma1 = sigma_equity(i).*(equity(i)./(equity(i) + debt(i)));
                v1 = debt(i) + equity(i);
                error = 1;
                itern = 0; % number of iteration
                while error >= 0.001 % iteratively solve for asset value and its volatility
                    itern = itern + 1;
                    if itern > 100
                        break;
                        disp('Not converge to solution within 100 iterations, broken from the iteration');
                    elseif any(~([v1,sigma1] > 0))
                        v1 = NaN;
                        sigma1 = NaN;
                        break;
                        disp('Negative asset value or volatility encountered, broken from the iteration');
                    end
                    v0 = v1;
                    sigma0 = sigma1;
                    solverOptions = optimset('TolX',1e-15);   % Option to display output
                    [v1, ~, exitflag1(i)] = fsolve(@(x) BSMFormula(x, equity(i), debt(i), rfr, sigma0, T), v0, solverOptions);
                    [sigma1, ~, exitflag2(i)] = fsolve(@(x) BSM_Vol(equity(i), debt(i), v1, rfr, x, sigma_equity(i), T), sigma0, solverOptions);
                    error = abs(sigma1 - sigma0);
                end
%                 [result, ~, exitflag2(i)] = fsolve(@(x) BSMFormula_V2(equity(i), debt(i), rfr, x, sigma_equity(i), T), [v0, sigma0], solverOptions);
                
                value_asset(:,i) = v1;
                sigma_asset(:,i) = sigma1;
                rtn_asset(:,i) = rfr; % annulized return
            end
        end
    end
end
function balance = BSMFormula(V, E, F, rfr, sigma, T)
    % Black-Scholes-Merton option pricing formula: E = V*N(d1) - exp(-rT)*F*N(D2)
    d1 = (log(V./F) + (rfr + 0.5*(sigma.^2)).*T)./(sigma.*sqrt(T));
    d2 = d1 - sigma*sqrt(T);
    lefthand = E;
    righthand = V.*cdf('Normal',d1,0,1) - exp(-rfr.*T).*F.*cdf('Normal',d2,0,1);
    balance = lefthand - righthand;
end
function balance = BSM_Vol(E, F, V, rfr, sigma, sigma_E, T)
    % Equation: sigma_E = (V/E)*N(d1)*sigma
    d1 = (log(V./F) + (rfr + 0.5*(sigma.^2)).*T)./(sigma.*sqrt(T));
    balance = sigma_E - (V./E)*cdf('Normal',d1,0,1)*sigma;
end
% function balance = BSMFormula_V2(E, F, rfr, X, sigma_E, T)
%     V = X(1);
%     sigma = X(2);
%
%     % Equation1: Black-Scholes-Merton option pricing formula: E = V*N(d1) - exp(-rT)*F*N(D2)
%     d1 = (log(V./F) + (rfr + 0.5*(sigma.^2)).*T)./(sigma.*sqrt(T));
%     d2 = d1 - sigma*sqrt(T);
%     balance(1) = V.*cdf('Normal',d1,0,1) - exp(-rfr.*T).*F.*cdf('Normal',d2,0,1) - E;
%
%     % Equation2: sigma_E = (V/E)*N(d1)*sigma
%     balance(2) = sigma_E - (V./E)*cdf('Normal',d1,0,1)*sigma;
% end
