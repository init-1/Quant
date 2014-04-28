classdef Model < Exportable
    properties
        owner
    end
    
    properties (Dependent, SetAccess = protected)
        dates
        aggid
        %%% Note there is a secids inheriented from Exportable
    end
    
    methods
        function o = Model(id, varargin)
        % Constructor of a Model. 
        % Model is the base class for RiskModel and TCModel, both of which have some thing
        % in common, like belonging to a dataset (as its owner), having dates and aggid
        % properties (though for case of having a dataset as a owner, these properties are
        % referenced to the owner).
        % Model can also have a NULL owner, i.e., no owner; in this case, user should
        % provide dates and aggid and an artificial owner is build insider the function.
        % Concretd subclasses should call this way:
        %     o = Model(id, owner, ...);
        %     o = Model(id, dates, aggid, isLive, ...);
        % where
        %      id: the identifier of the model
        %   owner: an AXDataSet object
        %   dates: a vector of numerical dates
        %   aggid: universe id
        %     ...: any other information needed to load model data
        
            o = o@Exportable(id, 'MODEL');
            if isa(varargin{1}, 'AXDataSet')
                o.owner = varargin{1};
                o = load(o, varargin{2:end});
                o.owner(o.id) = o;  % add this model to its owner (an AXDataSet object)
            else  % an artificial onwer gonna be created
                FTSASSERT(nargin > 3 && isnumeric(varargin{1}) ...
                    , 'Usage: Model(id, owner, ...) or Model(id, dates, aggid, islive...)');
                o.owner.dates = varargin{1};
                o.owner.aggid = varargin{2};
                o.owner.isLive = varargin{3};
                o = load(o, varargin{4:end});
            end
        end
        
        function dt = get.dates(o)
            dt = o.owner.dates;
        end
        
        function aid = get.aggid(o)
            aid = o.owner.aggid;
        end
    end
    
    methods(Access = protected)
        o = load(o, varargin)
    end
end

