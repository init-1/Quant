classdef Exportable
    properties (SetAccess = protected)
        id = '';
        type = '';
    end
    
    properties(Dependent, SetAccess = private, GetAccess = protected)
        ws
        date
        javadate
        secids
    end
    
    methods (Abstract)
        export(o, varargin);
    end
    
    methods
        function o = Exportable(id, type)
            FTSASSERT(ischar(type) && isrow(type), 'type must be a char-type string');
            FTSASSERT(ischar(id) && isrow(id), 'id must be a char-type string');
            o.type = type;
            o.id = upper(regexprep(id, '\s', '_'));
        end
        
        function ws = get.ws(~)
            ws = AXOptimization().ws;
        end
        
        function date = get.date(~)
            date = AXOptimization().date;
        end
        
        function jdate = get.javadate(~)
            jdate = AXOptimization().javadate;
        end
        
        function sids = get.secids(~)
            sids = AXOptimization().secids;
        end
        
        function st = getSelectionType(~, id)
            st = AXOptimization().getSelectionType(id);
        end
        
        function d = getData(~,id)
            d = AXOptimization().getData(id);
        end
    end  % of methods
end