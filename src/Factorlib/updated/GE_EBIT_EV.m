classdef GE_EBIT_EV < GlobalEnhanced
    %GE_EBIT_EV <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            EBIT_Q = o.loadItem(secIds, 'D000112407', startDate, endDate);
            EBIT_A = o.loadItem(secIds, 'D000110473', startDate, endDate);
            EV_Q = o.loadItem(secIds, 'D000111739', startDate, endDate);
            EV_A = o.loadItem(secIds, 'D000110514', startDate, endDate);
            
            EBIT = EBIT_Q;
            index = isnan(fts2mat(EBIT_Q));
            EBIT(index) = EBIT_A(index);
            
            EV = EV_Q;
            EV(index) = EV_A(index);  % original code using this index
            factorTS = EBIT ./ EV;
        end
    end
end
