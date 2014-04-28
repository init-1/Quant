classdef COMOVE_WED < FacBase
    %COMOVE_WED <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:05
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            win = 24;
            nSec = 50;
            universe = {'00053','000524248','000530824'};
            prcItemid = 'D001410446'; %TRI
            betaItemid = 'D001500002';
            isLive = 0;
            
            if ~iscell(secIds)
                secIds = {secIds};
            end
            
            %% Step 1 - Generate dates as backtest dates and data in principle should be aligned against dates
            sDate = datestr(addtodate(datenum(startDate),-win-1,'M'),'yyyy-mm-dd');
            dates = o.genDates(sDate, endDate, o.targetFreq);    % 'Busday', 0, 'EW', 5); % weekly data on Wedesday
            
            %% Step 2 - Get the index holdings and prc data
            [hldgs_ids, ~] = LoadIndexHoldingTS(universe,sDate,endDate,isLive);
            hldgs_prc = o.loadItem(hldgs_ids,prcItemid,sDate,endDate);
            hldgs_beta = o.loadItem(hldgs_ids,betaItemid,sDate,endDate);
            [hldgs_prc, hldgs_beta] = aligndates(hldgs_prc, hldgs_beta, dates);
            
            hldgs_ret = Price2Return(hldgs_prc,1);
            
            %% Step 3 - aligndata
            [hldgs_ret,hldgs_beta] = aligndata(hldgs_ret,hldgs_beta,hldgs_ret.dates);
            
            %% Step 4 - Backfill data
            hldgs_beta = backfill(hldgs_beta,100,'entry');
            
            %% Step 5 - replace the missing beta values with 1
            hldgs_beta(isnan(fts2mat(hldgs_beta))) = 1;
            
            [~,sec_loc] = ismember(secIds,hldgs_ids);
            sec_ret  = hldgs_ret(:,sec_loc);
            sec_beta = hldgs_beta(:,sec_loc);
            
            %% Step 6 - align data%         [hldgs_ret,sec_ret,hldgs_beta,sec_beta] = aligndates(hldgs_ret,sec_ret,hldgs_beta,sec_beta,dates);
            
            %% Step 7 - Calculate factor
            factorTS = sec_ret;
            factorTS(:,:) = NaN;
            
            for t = win:length(dates)
                disp([num2str(t-win+1) ' in progress...']);
                % prepare the correlation matrix for the return window series
                covRet = cov(hldgs_ret(t-win+1:t,:));
                sdRet = sqrt(diag(covRet));
                corr_mat = covRet./(sdRet*sdRet');
                [cval, cloc] = sort(corr_mat,2,'descend');
                dCorr = diag(corr_mat);
                isvalid = ~isnan(dCorr(sec_loc))';
                for n=1:numel(secIds)
                    if isvalid(n)
                        start_idx = sum(isnan(cval(sec_loc(n),:)))+1;
                        cmPortRet = hldgs_ret(t,cloc(sec_loc(n), start_idx+1:start_idx+nSec));
                        cmPortBeta = hldgs_beta(t,cloc(sec_loc(n), start_idx+1:start_idx+nSec));
                        factorTS(t,n) = -(bsxfun(@minus, bsxfun(@times, sec_ret(t,n)/sec_beta(t,n), csmean(cmPortBeta)), csmean(cmPortRet)));
                        
                    end
                end
            end
            
            % generate the date series with actual startdate and enddate
            dates = o.genDates(startDate, endDate, o.targetFreq);    % 'Busday', 0, 'EW', 5); % weekly data on Wedesday
            factorTS = aligndates(factorTS,dates);
            factorTS(isinf(fts2mat(factorTS))) = NaN;
            
        end
    end
end
