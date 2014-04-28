classdef RTRNCHM < FacBase
    %RTRNCHM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:13
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            % suppose whatever targetFreq is, always use its 3- and 6-lagged
            % values in terms of targetFreq.
            % By the definition of the factor, targetFreq should be 'M'.
            startDate = datestr(datenum(startDate)-3*31, 'yyyy-mm-dd');    % go back at least 3Ms
            AR = o.loadItem(secIds, 'D000686144', startDate, endDate, 6); % Account Receivalbe
            AP = o.loadItem(secIds, 'D000685855', startDate, endDate, 6); % Account Payable
            
            AR = movfunPIT(AR, 4, @nanmean);
            AP = movfunPIT(AP, 4, @nanmean);
            delta_AR = 1/2 * (AR{2} + AR{3}) ./ AR{1};
            delta_AP = 1/2 * (AP{2} + AP{3}) ./ AP{1};
            
            factorTS = delta_AR - delta_AP;
            factorTS = backfill(factorTS, o.DCF('3M'), 'entry');
        end
    end
end
