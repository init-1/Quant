classdef RESMMT < FacBase
    %RESMMT <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:11

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sdate = datestr(datenum(startDate)-370, 'yyyy-mm-dd');
            ret = Price2Return(o.loadItem(secIds,'D001410415',sdate,endDate), o.DCF('M'));
            bmRet = Price2Return(LoadIndexItemTS('00053', 'D000800522', sdate, endDate, o.dateBasis.freqBasis),o.DCF('M'));
            predBeta = o.loadItem(secIds, 'D001500001', sdate, endDate);
            if isempty(predBeta)
                predBeta = myfints(ret.dates, ones(size(ret)), fieldnames(ret,1));
            end
            predBeta(isnan(predBeta)) = 1;
            [ret, bmRet, predBeta] = aligndates(ret, bmRet, predBeta, o.freq);
            factorTS = ftsmovsum(ret - bsxfun(@times, predBeta, bmRet), o.DCF('12M'), true);
        end
    end
end
