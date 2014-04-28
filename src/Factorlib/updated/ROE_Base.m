classdef ROE_Base < FacBase
    %ROE_Base <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:12
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate, ret)
            totequity = o.loadItem(secIds, 'D000686136', startDate, endDate, 4);
            for i = 1:4
                totequity{i} = o.lagfts(totequity{i}, '12M');
            end
            
            ret_sum = ftsnanmean(ret{1:4})*4;
            totequity_avg = ftsnanmean(totequity{1:4});
            ret_sum = aligndates(ret_sum, totequity_avg.dates);
            factorTS = ret_sum ./ totequity_avg;
            factorTS = backfill(factorTS, o.DCF('3M'), 'entry');
        end
    end
end
