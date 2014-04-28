classdef Model
    properties (SetAccess = protected)
        dates
        aggid
        isLive
        %%% Note there is a secids inheriented from Exportable
    end
    
    methods
        function o = Model(aggid, dates, isLive)
        % owner should be a DataSet
            if ~iscell(aggid), aggid = {aggid}; end
            o.dates = datenum(dates);
            o.aggid = aggid;
            o.isLive = isLive;
            o = load(o);
        end
    end    
    
    methods (Abstract, Access = protected)
        o = load(o)
    end
end

