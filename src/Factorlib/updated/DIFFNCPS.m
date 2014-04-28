classdef DIFFNCPS < FacBase
    %DIFFN Diffusion on CPS
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
            CPS_NU_FY1 = o.loadItem(secIds,'D000434824',sDate,endDate);
            CPS_ND_FY1 = o.loadItem(secIds,'D000434804',sDate,endDate);
            CPS_NE_FY1 = o.loadItem(secIds,'D000434814',sDate,endDate);
            CPS_NU_FY2 = o.loadItem(secIds,'D000434825',sDate,endDate);
            CPS_ND_FY2 = o.loadItem(secIds,'D000434805',sDate,endDate);
            CPS_NE_FY2 = o.loadItem(secIds,'D000434815',sDate,endDate);
        
            % align all data to the dates time series
            Dates = o.genDates(startDate, endDate, o.freq);    % 'Busday', 0);
            [CPS_NU_FY1,CPS_ND_FY1,CPS_NE_FY1,CPS_NU_FY2,CPS_ND_FY2,CPS_NE_FY2]= aligndata(CPS_NU_FY1,CPS_ND_FY1,CPS_NE_FY1,CPS_NU_FY2,CPS_ND_FY2,CPS_NE_FY2,Dates);
        
            % backfill by 2 month data
            CPS_NU_FY1 = backfill(CPS_NU_FY1, o.DCF('2M'), 'entry');
            CPS_ND_FY1 = backfill(CPS_ND_FY1, o.DCF('2M'), 'entry');
            CPS_NE_FY1 = backfill(CPS_NE_FY1, o.DCF('2M'), 'entry');
            CPS_NU_FY2 = backfill(CPS_NU_FY2, o.DCF('2M'), 'entry');
            CPS_ND_FY2 = backfill(CPS_ND_FY2, o.DCF('2M'), 'entry');
            CPS_NE_FY2 = backfill(CPS_NE_FY2, o.DCF('2M'), 'entry');
            
            CPS_NU_FY1(isnan(fts2mat(CPS_NU_FY1))) = 0;
            CPS_ND_FY1(isnan(fts2mat(CPS_ND_FY1))) = 0;
            CPS_NE_FY1(isnan(fts2mat(CPS_NE_FY1))) = 0;
            CPS_NU_FY2(isnan(fts2mat(CPS_NU_FY2))) = 0;
            CPS_ND_FY2(isnan(fts2mat(CPS_ND_FY2))) = 0;
            CPS_NE_FY2(isnan(fts2mat(CPS_NE_FY2))) = 0;
            
            factorTS = ((CPS_NU_FY1 + CPS_NU_FY2) - (CPS_ND_FY1 + CPS_ND_FY2))./(CPS_NE_FY1 + CPS_NE_FY2);
        end
    end
end
