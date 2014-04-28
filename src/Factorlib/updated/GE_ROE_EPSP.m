classdef GE_ROE_EPSP < GlobalEnhanced
    %GE_ROE_EPSP <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:26

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            if o.isLive
                EPS = o.loadItem(secIds, 'D000110087', startDate, endDate);
                BPS = o.loadItem(secIds, 'D000110018', startDate, endDate);
            else
                BPS = o.loadItem(secIds, 'D000110113', startDate, endDate);
                EPS_Q = o.loadItem(secIds, 'D000110193', startDate, endDate);
                EPS_A = o.loadItem(secIds, 'D000110087', startDate, endDate);
                EPS = EPS_Q;
                index = isnan(fts2mat(EPS));
                EPS(index) = EPS_A(index);
            end
            
            factorTS =EPS ./ BPS;
        end
    end
end
