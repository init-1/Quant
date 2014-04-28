classdef DIFFNBPS < FacBase
    %DIFFN Diffusion on BPS
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
            BPS_NU_FY1 = o.loadItem(secIds,'D000434664',sDate,endDate);
            BPS_ND_FY1 = o.loadItem(secIds,'D000434644',sDate,endDate);
            BPS_NE_FY1 = o.loadItem(secIds,'D000434654',sDate,endDate);
            BPS_NU_FY2 = o.loadItem(secIds,'D000434665',sDate,endDate);
            BPS_ND_FY2 = o.loadItem(secIds,'D000434645',sDate,endDate);
            BPS_NE_FY2 = o.loadItem(secIds,'D000434655',sDate,endDate);
        
            Dates = o.genDates(startDate, endDate, o.freq);    % 'Busday', 0);
            [BPS_NU_FY1,BPS_ND_FY1,BPS_NE_FY1,BPS_NU_FY2,BPS_ND_FY2,BPS_NE_FY2]= aligndata(BPS_NU_FY1,BPS_ND_FY1,BPS_NE_FY1,BPS_NU_FY2,BPS_ND_FY2,BPS_NE_FY2,Dates);
        
            % backfill by 2 month data
            BPS_NU_FY1 = backfill(BPS_NU_FY1, o.DCF('2M'), 'entry');
            BPS_ND_FY1 = backfill(BPS_ND_FY1, o.DCF('2M'), 'entry');
            BPS_NE_FY1 = backfill(BPS_NE_FY1, o.DCF('2M'), 'entry');
            BPS_NU_FY2 = backfill(BPS_NU_FY2, o.DCF('2M'), 'entry');
            BPS_ND_FY2 = backfill(BPS_ND_FY2, o.DCF('2M'), 'entry');
            BPS_NE_FY2 = backfill(BPS_NE_FY2, o.DCF('2M'), 'entry');
            
            BPS_NU_FY1(isnan(fts2mat(BPS_NU_FY1))) = 0;
            BPS_ND_FY1(isnan(fts2mat(BPS_ND_FY1))) = 0;
            BPS_NE_FY1(isnan(fts2mat(BPS_NE_FY1))) = 0;
            BPS_NU_FY2(isnan(fts2mat(BPS_NU_FY2))) = 0;
            BPS_ND_FY2(isnan(fts2mat(BPS_ND_FY2))) = 0;
            BPS_NE_FY2(isnan(fts2mat(BPS_NE_FY2))) = 0;
            
            factorTS = ((BPS_NU_FY1 + BPS_NU_FY2) - (BPS_ND_FY1 + BPS_ND_FY2))./(BPS_NE_FY1 + BPS_NE_FY2);
        end
    end
end
