classdef DIFFN < FacBase
    %DIFFN Diffusion on EPS
    %
    %  Formula:
    %    {Diffusion} = ({Total Up Estimates} - {Total Down Estimates}) / {Total Estimates}
    %  where
    %    {Total Up Estimates} = {Up Estimates}_{1 year forward} + {Up Estimates}_{2 year forward}
    %    {Total Down Estimates} = {Down Estimates}_{1 year forward} + {Down Estimates}_{2 year forward}
    %    {Total Estimates} = {Number of Estimates}_{1 year forward} + {Number of Estimates}_{2 year forward}
    %
    %  Description:
    %    Earnings surprises are highly correlated with stock price movement.
    %    Much of this price movement occurs prior to actual earnings release date.
    %    In order to profit from this phenomenon, it is necessary to identify stocks
    %    that are likely to show an earnings surprise.
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:06
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(addtodate(datenum(startDate),-2,'M'),'yyyy-mm-dd');
            EPS_NU_FY1 = o.loadItem(secIds,'D000435624',sDate,endDate);
            EPS_ND_FY1 = o.loadItem(secIds,'D000435604',sDate,endDate);
            EPS_NE_FY1 = o.loadItem(secIds,'D000435614',sDate,endDate);
            EPS_NU_FY2 = o.loadItem(secIds,'D000435625',sDate,endDate);
            EPS_ND_FY2 = o.loadItem(secIds,'D000435605',sDate,endDate);
            EPS_NE_FY2 = o.loadItem(secIds,'D000435615',sDate,endDate);
            
            % align all data to the dates time series
            Dates = o.genDates(startDate, endDate, o.freq);    % 'Busday', 0);
            [EPS_NU_FY1,EPS_ND_FY1,EPS_NE_FY1,EPS_NU_FY2,EPS_ND_FY2,EPS_NE_FY2]= aligndata(EPS_NU_FY1,EPS_ND_FY1,EPS_NE_FY1,EPS_NU_FY2,EPS_ND_FY2,EPS_NE_FY2,Dates);
            
            % backfill by 2 month data
            EPS_NU_FY1 = backfill(EPS_NU_FY1, o.DCF('2M'), 'entry');
            EPS_ND_FY1 = backfill(EPS_ND_FY1, o.DCF('2M'), 'entry');
            EPS_NE_FY1 = backfill(EPS_NE_FY1, o.DCF('2M'), 'entry');
            EPS_NU_FY2 = backfill(EPS_NU_FY2, o.DCF('2M'), 'entry');
            EPS_ND_FY2 = backfill(EPS_ND_FY2, o.DCF('2M'), 'entry');
            EPS_NE_FY2 = backfill(EPS_NE_FY2, o.DCF('2M'), 'entry');
            
            %% Step 3: calculate factor value
            EPS_NU_FY1(isnan(fts2mat(EPS_NU_FY1))) = 0;
            EPS_ND_FY1(isnan(fts2mat(EPS_ND_FY1))) = 0;
            EPS_NE_FY1(isnan(fts2mat(EPS_NE_FY1))) = 0;
            EPS_NU_FY2(isnan(fts2mat(EPS_NU_FY2))) = 0;
            EPS_ND_FY2(isnan(fts2mat(EPS_ND_FY2))) = 0;
            EPS_NE_FY2(isnan(fts2mat(EPS_NE_FY2))) = 0;
            
            factorTS = ((EPS_NU_FY1 + EPS_NU_FY2) - (EPS_ND_FY1 + EPS_ND_FY2))./(EPS_NE_FY1 + EPS_NE_FY2);
        end
    end
end
