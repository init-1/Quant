classdef HISERNM < FacBase
    %HISERNM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:09
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            epsQtr = o.loadItem(secIds,'D000685786',sDate,endDate,5);
            % closePrice = o.loadItem(secIds,'D001410415',sDatePr,endDate);
            
            epsCurrent = ftsnanmean(epsQtr{1:4})*4;
            epsLag = ftsnanmean(epsQtr{2:5})*4;
            
            nbf = o.DCF('3M');
            epsCurrent = backfill(epsCurrent, nbf, 'entry');
            epsLag = backfill(epsLag, nbf, 'entry');
            
            factorTS = (epsCurrent - epsLag)./((abs(epsCurrent) + abs(epsLag))/2);
        end
    end
end
