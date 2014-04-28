classdef GE_EPS_3M_Surprise_RIG < GB_EPS_Surprise_RIG
    %GE_EPS_3M_Surprise_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23

    methods (Access = protected)
        function varargout = build(o, secIds, startDate, endDate)
            varargout = cell(1, max(nargout,1));
            [varargout{:}] = build@GB_EPS_Surprise_RIG(o, secIds, startDate, endDate, '3M');
        end
    end
end
