classdef GE_Mom_3M_EPSFY1 < GB_Mom_EPSFY1
    %GE_Mom_3M_EPSFY1 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24

    methods (Access = protected)
        function varargout = build(o, secIds, startDate, endDate)
            varargout = cell(1, max(nargout,1));
            [varargout{:}] = build@GB_Mom_EPSFY1(o, secIds, startDate, endDate, '3M');
        end
    end
end
