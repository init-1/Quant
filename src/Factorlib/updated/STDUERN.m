classdef STDUERN < FacBase
    %STDUERN <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:14
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            nQtrs = 12;
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            eps = o.loadItem(secIds,'D000685786',sDate,endDate,nQtrs);
            unexp = cell(1,8); % unexpected earnings
            for i = 1:8
                unexp{i} = eps{i} - eps{i+4};
            end
            factorTS = unexp{1}./ftsnanstd(unexp{:});
            factorTS = backfill(factorTS, o.DCF('3M'), 'entry');
        end
    end
end
