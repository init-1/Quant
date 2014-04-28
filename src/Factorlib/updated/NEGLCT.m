classdef NEGLCT < FacBase
    %NEGLCT <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:10

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            factorTS = o.loadItem(secIds, 'D000435614', startDate, endDate);
            factorTS(isnan(factorTS)) = 0; % uncovered stocks has the most potential
            factorTS = -log(1+factorTS);
        end
    end
end
