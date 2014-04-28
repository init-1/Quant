classdef OPCFTP_V2 < FacBase
    %OPCFTP <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:10

    methods (Access = protected)
        % build function for Class: OPCFTP
        function factorTS = build(o, secIds, startDate, endDate)
            sDate_Sh = datestr(addtodate(datenum(startDate),-15,'M'),'yyyy-mm-dd'); % financial
            sDate_FS = datestr(addtodate(datenum(startDate),-3,'M'),'yyyy-mm-dd'); % financial statement item start retrieving Date

            Qtrs = 8;
            shares = o.loadItem(secIds,'D001410472',sDate_Sh,endDate);
            closePrice = o.loadItem(secIds,'D001410415',sDate_Sh,endDate);
            CFO = o.loadItem(secIds,'D000679450',sDate_FS,endDate,Qtrs);
            % FQTR = o.loadItem(secIds,'D000647426',sDate_FS,endDate,Qtrs);
            
            CFO_Sum = ftsnanmean(CFO{1:4})*4;
            CFO_Sum = backfill(CFO_Sum, o.DCF('3M'), 'entry');
            
            [CFO_Sum,closePrice,shares] = aligndates(CFO_Sum,closePrice,shares);

            % multiply CFO_SumMean by 1 million because data in compustat is in unit of million
            factorTS = (CFO_Sum./shares)./closePrice*1000000;
        end
    end
end
