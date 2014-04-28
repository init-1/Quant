classdef QCKRCHG < FacBase
    %QCKRCHG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:11

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            asset     = o.loadItem(secIds, 'D000686131', sDate, endDate, 8);
            inventory = o.loadItem(secIds, 'D000679620', sDate, endDate, 8);
            liability = o.loadItem(secIds, 'D000686132', sDate, endDate, 8);
            
            current = ratio(asset(1:4), inventory(1:4), liability(1:4));
            lagged  = ratio(asset(5:8), inventory(5:8), liability(5:8)); % 1-y lagged
            
            factorTS = lagged - current;
            factorTS = backfill(factorTS, o.DCF('3M'), 'entry');
            
            function ratio = ratio(asset, inventory, liability)
                asset     = ftsnanmean(asset{:});
                inventory = ftsnanmean(inventory{:});
                liability = ftsnanmean(liability{:});
                ratio = (asset - inventory) / liability;
            end
        end
    end
end
