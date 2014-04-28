classdef ACCACRUAGG < ACCACRU_Base
    %ACCACRUAGG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:03

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            fts1 = build@ACCACRU_Base(o, secIds, startDate, endDate, 'D000686144');
            fts2 = build@ACCACRU_Base(o, secIds, startDate, endDate, 'D000685855');
            fts3 = build@ACCACRU_Base(o, secIds, startDate, endDate, 'D000679620');
            [fts1,fts2,fts3] = aligndata(fts1,fts2,fts3);
            factorTS = ftsnansum(fts1, fts2, fts3);
        end
    end
end
