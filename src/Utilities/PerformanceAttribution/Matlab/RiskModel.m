classdef RiskModel < Model
    properties
        faccov
        exposure
        specrisk
        beta
    end
    
    properties (Dependent)
        facids
    end
    
    methods
        function o = RiskModel(aggid, dates, varargin)
        % owner should be a DataSet
            o = o@Model(aggid, dates, varargin{:});
        end
        
        function fids = get.facids(o)
            fids = fieldnames(o.faccov, 1, 1);
        end
    end
end

    