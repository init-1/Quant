classdef GE_DY_Potential_RIG < GlobalEnhanced
    %GE_DY_Potential_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-4*370, 'yyyy-mm-dd');
            W_DPS = o.loadItem(secIds, 'D000110146', sDate, endDate);
            W_DPS = backfill(W_DPS, o.DCF('15M'), 'entry');
            IB_EPS_FY2 = o.loadItem(secIds, 'D000411365', startDate, endDate);
            if o.isLive
                W_Close = o.loadItem(secIds, 'D000110013', startDate, endDate);
                IB_Close = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                W_Close = o.loadItem(secIds, 'D000411365', startDate, endDate);
                IB_Close = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            
            GE = o.estGrowth(W_DPS, o.DCF('12M'), o.DCF('4M'));
            [W_DPS,GE,IB_EPS_FY2,W_Close,IB_Close] = aligndates(W_DPS,GE,IB_EPS_FY2,W_Close,IB_Close,gics.dates);
            
            D3S = W_DPS .* (1+GE).^3;
            D3SYield = D3S ./ W_Close .* IB_Close;
            Idx = fts2mat(W_Close) > 0 & fts2mat(IB_Close) > 0;
            D3SYield(~Idx) = NaN;
            VPS = IB_EPS_FY2 * 0.4;
            VPS(VPS <= D3SYield) = D3SYield(VPS <= D3SYield);
            factorTS = o.RIG(VPS, gics);
        end
    end
end
