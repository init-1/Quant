classdef SALESTP < FacBase
    %SALESTP <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:13
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            sales = o.loadItem(secIds, 'D000686629', sDate, endDate, 4);
            price = o.loadItem(secIds, 'D001410415', sDate, endDate);
            shares = o.loadItem(secIds, 'D001410472', sDate, endDate);
            sales = ftsnansum(sales{1:4});
            
            sales = backfill(sales, o.DCF('3M'), 'entry');  % use newest price and shares data
            factorTS = sales ./ (shares .* price);
        end
    end
end
