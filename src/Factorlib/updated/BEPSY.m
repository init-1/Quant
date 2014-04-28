classdef BEPSY < FacBase
    %BEPSY Blended EPS Yield
    %
    %  Formula:
    %    {Blended EPS Yield} = {Blended Stock EPS} / {Stock Price}
    %
    %    All income statement items are annualized by summing up last four quarter values. 
    %    If both actual EPS and estimate EPS available, blended stock EPS is average of 
    %    the two; if only one of them is available, blended stock EPS is
    %    the one available; otherwise, blended stock EPS is null
    %  
    %  Description:
    %    Rather than behaving rationally as implied in standard financial theory, 
    %    investors tend to make systematic cognitive errors which a truly objective 
    %    investor can exploit.  Such errors include overreacting to bad news, 
    %    confusing a bad company with a bad stock, and assuming poorly performing stocks
    %    will continue to behave badly.  Each of these can result in an inappropriately 
    %    low stock price ÿ which can lead to investment opportunity
    % 
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:03

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            % set the sDate 3 month earlier than the input startDate to ensure some look back
            % for the first observation
            sDate = datestr(addtodate(datenum(startDate),-3,'M'),'yyyy-mm-dd');
            EPS_Act = o.loadItem(secIds,'D000432130',sDate,endDate);
            if o.isLive
                EPS_FY1 = o.loadItem(secIds,'D000448965',sDate,endDate); % QFS FY1 EPS mean
            else            
                EPS_FY1 = o.loadItem(secIds,'D000435584',sDate,endDate);
            end
            closePrice = o.loadItem(secIds,'D001410415',sDate,endDate);
            
            % match the items
            EPS_Act = backfill(EPS_Act,o.DCF('2M'),'entry');
            EPS_FY1 = backfill(EPS_FY1,o.DCF('2M'),'entry');
            
            % calculate factor value
            EPS_Blended = ftsnanmean(EPS_Act, EPS_FY1);
            factorTS = EPS_Blended ./ closePrice;
        end
    end
end
