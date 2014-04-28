classdef DIFFNDPS < FacBase
    %DIFFN Diffusion on DPS
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
            DPS_NU_FY1 = o.loadItem(secIds,'D000434984',sDate,endDate);
            DPS_ND_FY1 = o.loadItem(secIds,'D000434964',sDate,endDate);
            DPS_NE_FY1 = o.loadItem(secIds,'D000434974',sDate,endDate);
            DPS_NU_FY2 = o.loadItem(secIds,'D000434985',sDate,endDate);
            DPS_ND_FY2 = o.loadItem(secIds,'D000434965',sDate,endDate);
            DPS_NE_FY2 = o.loadItem(secIds,'D000434975',sDate,endDate);
        
            Dates = o.genDates(startDate, endDate, o.freq);    % 'Busday', 0);
            [DPS_NU_FY1,DPS_ND_FY1,DPS_NE_FY1,DPS_NU_FY2,DPS_ND_FY2,DPS_NE_FY2]= aligndata(DPS_NU_FY1,DPS_ND_FY1,DPS_NE_FY1,DPS_NU_FY2,DPS_ND_FY2,DPS_NE_FY2,Dates);
        
            % backfill by 2 month data
            DPS_NU_FY1 = backfill(DPS_NU_FY1, o.DCF('2M'), 'entry');
            DPS_ND_FY1 = backfill(DPS_ND_FY1, o.DCF('2M'), 'entry');
            DPS_NE_FY1 = backfill(DPS_NE_FY1, o.DCF('2M'), 'entry');
            DPS_NU_FY2 = backfill(DPS_NU_FY2, o.DCF('2M'), 'entry');
            DPS_ND_FY2 = backfill(DPS_ND_FY2, o.DCF('2M'), 'entry');
            DPS_NE_FY2 = backfill(DPS_NE_FY2, o.DCF('2M'), 'entry');
            
            DPS_NU_FY1(isnan(fts2mat(DPS_NU_FY1))) = 0;
            DPS_ND_FY1(isnan(fts2mat(DPS_ND_FY1))) = 0;
            DPS_NE_FY1(isnan(fts2mat(DPS_NE_FY1))) = 0;
            DPS_NU_FY2(isnan(fts2mat(DPS_NU_FY2))) = 0;
            DPS_ND_FY2(isnan(fts2mat(DPS_ND_FY2))) = 0;
            DPS_NE_FY2(isnan(fts2mat(DPS_NE_FY2))) = 0;
            
            factorTS = ((DPS_NU_FY1 + DPS_NU_FY2) - (DPS_ND_FY1 + DPS_ND_FY2))./(DPS_NE_FY1 + DPS_NE_FY2);
        end
    end
end
