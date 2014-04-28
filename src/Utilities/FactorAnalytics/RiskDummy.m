classdef RiskDummy < RiskModel
    methods
        function o = RiskDummy(id, owner, varargin)
        % owner should be a DataSet
            o = o@RiskModel(id, owner, varargin{:});
        end
        
        function export(o)
            n = length(o.secids);
            com.axiomainc.portfolioprecision.FactorRiskModel(o.ws, o.id, o.secids, o.facids ...
                , zeros(1, n) ...   % specific risk
                , zeros(1, n) ...  % factor exposure
                , 1);           % factor covariance
        end
    end
    
    methods (Access = protected)
        function o = load(o)
            o.beta = copy(myfints, o.owner.universe);
            % beta will then be added to owner by RiskModel's constructor
        end
    end
end

    