classdef COMOVE < FacBase
    %COMOVE <a full descriptive name placed here>
    %  THIS SHOULD BE CHECK IF USED!!!!
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
            %% Step 1 - Generate dates as backtest dates and data in principle should be aligned against dates
            sDate = datestr(addtodate(datenum(startDate),-win-1,'M'),'yyyy-mm-dd');
            dates = o.genDates(sDate, endDate, o.targetFreq);    % 'Busday', 0);
            
            %% Step 2 - Get the index holdings and prc data
            hldgs_ids = LoadIndexHoldingTS(universe,sDate,endDate,isLive,targetFreq);
            run_idx = ismember(secIds,hldgs_ids);
            secIds_run = secIds(run_idx);
            
            hldgs_prc = o.loadItem(hldgs_ids,prcItemid,sDate,endDate);
            hldgs_beta = o.loadItem(hldgs_ids,betaItemid,sDate,endDate);
            hldgs_ret = Price2Return(hldgs_prc,1);
            
            %% Step 4 - Backfill data
            hldgs_beta = backfill(hldgs_beta,2,'entry');
            
            %% Step 5 - replace the missing beta values with 1
            hldgs_beta(isnan(fts2mat(hldgs_beta))) = 1;
            
            [~,sec_loc] = ismember(secIds_run,hldgs_ids);
            sec_ret  = hldgs_ret(:,sec_loc);
            sec_beta = hldgs_beta(:,sec_loc);
            
            %% Step 6 - align data[hldgs_ret,sec_ret,hldgs_beta,sec_beta] = aligndates(hldgs_ret,sec_ret,hldgs_beta,sec_beta,dates);
            
            %% Step 7 - Calculate factor
            factorTS_run = sec_ret;
            factorTS_run(:,:) = NaN;
            
            for t = win:length(dates)
                disp([num2str(t-win+1) ' in progress...']);
                % prepare the correlation matrix for the return window series
                covRet = cov(hldgs_ret(t-win+1:t,:));
                sdRet = sqrt(diag(covRet));
                corr_mat = covRet./(sdRet*sdRet');
                [cval, cloc] = sort(corr_mat,2,'descend');
                dCorr = diag(corr_mat);
                isvalid = ~isnan(dCorr(sec_loc))';
                for n=1:numel(secIds_run)
                    if isvalid(n)
                        start_idx = sum(isnan(cval(sec_loc(n),:)))+1;
                        cmPortRet = hldgs_ret(t,cloc(sec_loc(n), start_idx+1:start_idx+nSec));
                        cmPortBeta = hldgs_beta(t,cloc(sec_loc(n), start_idx+1:start_idx+nSec));
                        factorTS_run(t,n) = -(bsxfun(@minus, bsxfun(@times, sec_ret(t,n)/sec_beta(t,n), csmean(cmPortBeta)), csmean(cmPortRet)));
                        
                    end
                end
            end
            
            % generate the date series with actual startdate and enddate
            factorTS = myfints(factorTS_run.dates,nan(size(factorTS_run,1),length(secIds)),secIds);
            factorTS(:,run_idx) = factorTS_run;
        end
    end
end
