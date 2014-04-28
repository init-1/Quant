classdef DOLLARLIQUIDITY < FacBase
    %DOLLARLIQUIDITY <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:06

    methods (Access = protected)
        % build function for Class: BKTOPRICE
        function factorTS = build(o, secIds, startDate, endDate)
            price_in_USD_item = 'D001410415';
            trade_volueme_item = 'D001410431';
            sDate = datestr(datenum(startDate)-15, 'yyyy-mm-dd');
            price_USD = o.loadItem(secIds, price_in_USD_item, sDate, endDate);
            trade_volueme =o.loadItem(secIds, trade_volueme_item, sDate, endDate);
            factorTS = price_USD .* trade_volueme;
        end
    end
end
