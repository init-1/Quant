classdef RnDEfficiency < FacBase
    %RnDEfficiency <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:13

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-30*31,'yyyy-mm-dd');
            
            RnD = o.loadItem(secIds,'D000686681',sDate,endDate,4);
            sales = o.loadItem(secIds,'D000686629',sDate,endDate,4);
            sales = ftsnanmean(sales{:})*4;
            RnD = ftsnanmean(RnD{:})*4;
            
            RnDmat = fts2mat(RnD);
            Salesmat = fts2mat(sales);
            factorTS = RnD;
            factorTS(:,:) = nan;
            [T,nsec] = size(RnDmat);
            win = o.DCF('24M');
            lag = o.DCF('3M'); %1 quarter lagged RnD also included in the regression
            nregressors = 3;
            
            for t = win+lag:T
                for n = 1:nsec
                    ysample = Salesmat(t-win+1:t,n);
                    xsample = [ones(win,1) RnDmat(t-win+1:t,n) RnDmat(t-win-lag+1:t-lag,n)];
                    
                    idx = isnan(ysample) | isnan(xsample(:,2)) | isnan(xsample(:,3));
                    ysample(idx,:) = [];
                    xsample(idx,:) = [];
                    
                    if sum(idx) > 0.5*win || rank(xsample) < nregressors
                        factorTS(t,n) = nan;
                    else
                        b = regress(ysample,xsample);
                        factorTS(t,n) = 0.75*b(2,1) + 0.25*b(3,1);
                    end
                end
            end
        end
    end
end
