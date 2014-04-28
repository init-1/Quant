classdef RiskDummy < RiskModel
    methods
        function o = RiskDummy(id, varargin)
        % Usage:
        %     o = RiskDummy(id, owner);
        %     o = RiskDummy(id, dates, aggid, isLive);
        % where
        %      id: the identifier of the model
        %   owner: an AXDataSet object
        %   dates: a vector of numerical dates
        %   aggid: universe id
            o = o@RiskModel(id, varargin{:});            
        end
        
        function export(o)
            n = length(o.secids);
            com.axiomainc.portfolioprecision.FactorRiskModel(o.ws, o.id, o.secids, 'FACTOR1' ...
                , ones(1, n) ...   % specific risk
                , zeros(1, n) ...  % factor exposure
                , 1);              % factor covariance
        end
    end
    
    methods (Access = protected)
        function o = load(o)
            o.scale = 1;
            o.beta = o.owner.universe.map;
            % beta will then be added to owner by RiskModel's constructor
        end
    end
end

    