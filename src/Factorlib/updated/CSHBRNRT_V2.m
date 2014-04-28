classdef CSHBRNRT_V2 < FacBase
    %CSHBRNRT Cash Burn Rate
    %
    %  Formula:
    %    {Cash Burn Rate} = -({Operating Cash Flow}+{Investing Cash Flow}) / {Cash and Cash Equivalents}
    %  All balance sheet items are being averaged on last four quarter values
    %  All cash flow items are annualized by summing up last four quarter values
    %
    %  Description:
    %    It measures how long the cash and equivalents of technology companies can
    %    continue to sustain them during their growth phase, without the injection
    %    of external capital.
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:05
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');            
            cfo = o.loadItem(secIds, 'D000679450', sDate, endDate, 5); % Operating Cashflow
            cfi = o.loadItem(secIds, 'D000679449', sDate, endDate, 5); % investing Cashflow
            cash = o.loadItem(secIds, 'D000679586', sDate, endDate, 4);
            
            cfo_sum = ftsnanmean(cfo{1:4})*4;
            cfi_sum = ftsnanmean(cfi{1:4})*4;
            cash_avg = ftsnanmean(cash{1:4});
            factorTS = -(cfo_sum + cfi_sum) ./ cash_avg;
            factorTS = backfill(factorTS, o.DCF('4M'), 'entry'); %backfill 4M
        end
    end
end
