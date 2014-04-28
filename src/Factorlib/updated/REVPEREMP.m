classdef REVPEREMP < FacBase
    %REVPEREMP <a full descriptive name placed here>
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
            sales = o.loadItem(secIds, 'D000686629', sDate, endDate, 4);
            nEmployees  = o.loadItem(secIds, 'D000904558', sDate, endDate);
            
            factorTS = ftsnanmean(sales{1:4}) * 4;
            nEmployees = fill(nEmployees, inf, 'entry');
            factorTS = factorTS ./ (nEmployees * 1000);
        end
    end
end
