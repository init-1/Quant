classdef OPMRGIN_MOD < FacBase
    %OPMRGIN_MOD <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:10

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            EBITDA = o.loadItem(secIds, 'D000679559', sDate, endDate, 4);
%             dep = o.loadItem(secIds, 'D000685797', sDate, endDate, 4);
            dep = o.loadItem(secIds, 'D000686264', sDate, endDate, 4);
            revenue = o.loadItem(secIds, 'D000686629', sDate, endDate, 4);

            EBITDA = ftsnanmean(EBITDA{1:4}).*4;
            dep = ftsnanmean(dep{1:4}).*4;
            revenue = ftsnanmean(revenue{1:4}).*4;
            bc = cellfun(@(x){backfill(x,o.DCF('6M'),'entry')}, {EBITDA, dep, revenue});
            [EBITDA, dep, revenue] = bc{:};
            factorTS = (EBITDA - dep) ./ revenue;
        end
    end
end
