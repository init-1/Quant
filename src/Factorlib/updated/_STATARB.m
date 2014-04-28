classdef STATARB < FacBase
    %STATARB <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:13

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
        win = 60;
        nPCA = 6;
        universe = {'00053','000524248','000530824','0064984000','0069KLD400'};
        %universe = {'00053','000524248','000530824'};
        
        %prcItemid = 'D001410415';
        prcItemid = 'D001410446'; %TRI
        isLive = 0;
        
        %% Step 1 - Generate dates as backtest dates and data in principle should be aligned against dates
        sDate = datestr(addtodate(datenum(startDate),-win-1,'M'),'yyyy-mm-dd');
        dates = o.genDates(sDate, endDate, o.targetFreq);    % 'Busday', 0);
        
        %% Step 2 - Fetch Data
        hldgs_ids = LoadIndexHoldingTS(universe,sDate,endDate,isLive,targetFreq);
        hldgs_prc = o.loadItem(hldgs_ids,prcItemid,sDate,endDate);
        
        %% Step 4 - calculate the returns series
        hldgs_ret = Price2Return(hldgs_prc,1);
        
        %% Step 6 - align datahldgs_ret = aligndates(hldgs_ret,dates);
        % remove the first row cuz of all null
        hldgs_ret(1,:) = [];
        
        %% Step 7 - Calculate factor
        resTS = hldgs_ret;
        resTS(:,:) = NaN;
        
        % repeat following for each date
        for t = win:length(dates)-1
            disp([num2str(t-win+1) ' in progress...']);
            valIdx = not(any(isnan(fts2mat(hldgs_ret(t-win+1:t,:))),1));
            valHldgsRet = hldgs_ret(t-win+1:t,valIdx);
            
            % perform PCA
            [~, scorecmp, ~, ~] = princomp(fts2mat(valHldgsRet));
            
            % initialize output parameters
            rBeta = zeros(2, sum(valIdx));
            drift = zeros(1, sum(valIdx));
            meq = zeros(1, sum(valIdx));
            seq = zeros(1, sum(valIdx));
            sigmaeq = zeros(1, sum(valIdx));
            
            for n=1:numel(hldgs_ids(valIdx))
                % perform regression of secret w/ PCA 6 factors
                [sBeta,~,sRes,~] = regress(fts2mat(valHldgsRet(:,n)),[ones(size(scorecmp(:,1))), scorecmp(:,1:nPCA)]);
                sRes_lag = sRes(1:end-1);
                  
                % perform regression on the residuals[rBeta(:,n),~,rRes,~] = regress(sRes(2:end),[ones(length(sRes_lag),1), sRes_lag]);
        
                % output parameters
                drift(1,n) = sBeta(1,1);
                meq(1,n) = rBeta(1,n)./(1-rBeta(2,n));
                sigmaeq(1,n) = sqrt(cov(rRes)./(1-rBeta(2,n).^2));
                seq(1,n) =  -1 .* meq(1,n) ./ sigmaeq(1,n);
            end
            m_new = meq - nanmean(rBeta(1,:) ./ (1-rBeta(2,:)));
            s_new = -1 .* m_new ./ sigmaeq;
            resTS(t,valIdx) = s_new;
        end
        
        [run_idx, loc] = ismember(secIds,hldgs_ids);
        factorTS_run = resTS(:,loc(run_idx));
        
        % generate the date series with actual startdate and enddate
        dates = o.genDates(startDate, endDate, o.targetFreq);    % 'Busday', 0);
        factorTS_run = aligndates(factorTS_run,dates);
        factorTS_run(isinf(fts2mat(factorTS_run))) = NaN;
        
        factorTS = myfints(factorTS_run.dates,nan(size(factorTS_run,1),length(secIds)),QuantId2FieldId(secIds));
        factorTS(:,run_idx) = factorTS_run;
        
        end
        
        function [factorTS, priceDateStruct] = buildLive(o, secIds, endDate)
        win = 60;
        nPCA = 6;
        universe = {'00053','000524248','000530824','0064984000','0069KLD400'};
        prcItemid = 'D001410446'; %TRI
        isLive = 0;
        
        %% Step 1 - Generate dates as backtest dates and data in principle should be aligned against dates
        sDate = datestr(addtodate(datenum(endDate),-win-3,'M'),'yyyy-mm-dd');
        dates = o.genDates(sDate, endDate, o.targetFreq);    % 'Busday', 0,'ED', day(endDate));
        
        %% Step 2 - Fetch Data
        hldgs_ids = LoadIndexHoldingTS(universe,sDate,endDate,isLive,'M');
        hldgs_prc = o.loadItem(hldgs_ids,prcItemid,sDate,endDate);
        
        hldgs_prc = aligndates(hldgs_prc,dates);
        
        %% Step 4 - calculate the returns series
        hldgs_ret = Price2Return(hldgs_prc,1);
        
        %% Step 7 - Calculate factor
        resTS = hldgs_ret;
        resTS(:,:) = NaN;
        
        % repeat following for each date
        for t = win:length(dates)-1
            disp([num2str(t-win+1) ' in progress...']);
            valIdx = not(any(isnan(fts2mat(hldgs_ret(t-win+1:t,:))),1));
            valHldgsRet = hldgs_ret(t-win+1:t,valIdx);
            
            % perform PCA
            [~, scorecmp, ~, ~] = princomp(fts2mat(valHldgsRet));
            
            % initialize output parameters
            rBeta = zeros(2, sum(valIdx));
            drift = zeros(1, sum(valIdx));
            meq = zeros(1, sum(valIdx));
            seq = zeros(1, sum(valIdx));
            sigmaeq = zeros(1, sum(valIdx));
            
            for n=1:numel(hldgs_ids(valIdx))
                % perform regression of secret w/ PCA 6 factors
                [sBeta,~,sRes,~] = regress(fts2mat(valHldgsRet(:,n)),[ones(size(scorecmp(:,1))), scorecmp(:,1:nPCA)]);
                sRes_lag = sRes(1:end-1);
                  
                % perform regression on the residuals[rBeta(:,n),~,rRes,~] = regress(sRes(2:end),[ones(length(sRes_lag),1), sRes_lag]);
        
                % output parameters
                drift(1,n) = sBeta(1,1);
                meq(1,n) = rBeta(1,n)./(1-rBeta(2,n));
                sigmaeq(1,n) = sqrt(cov(rRes)./(1-rBeta(2,n).^2));
                seq(1,n) =  -1 .* meq(1,n) ./ sigmaeq(1,n);
            end
            m_new = meq - nanmean(rBeta(1,:) ./ (1-rBeta(2,:)));
            s_new = -1 .* m_new ./ sigmaeq;
            resTS(t,valIdx) = s_new;
        end
        
        [run_idx, loc] = ismember(secIds,hldgs_ids);
        factorTS_run = resTS(end,loc(run_idx));
        
        factorTS_run = factorTS_run(end,:);
        factorTS_run(isinf(fts2mat(factorTS_run))) = NaN;
        
        factorTS = myfints(factorTS_run.dates,nan(size(factorTS_run,1),length(secIds)),QuantId2FieldId(secIds));
        factorTS(:,run_idx) = factorTS_run;
        
        priceDateStruct = LatestDataDate(hldgs_prc);
        
        end
        
    end
end
