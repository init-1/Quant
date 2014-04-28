classdef AXConstraint < Exportable
    properties (Constant)
        SCOPES = {'ASSET', 'AGGREGATE', 'SELECTION', 'MEMBER'};
        PROPERTY_MAP = AXConstraint.initPropertyMap;
    end
    
    properties (Access = private);
        desc = '';
        selection = {};
        priority = 0;
        isEnabled = true;
        pnames = {};   % property names
        pvalues = {};  % property values
    end
    
    methods
        function o = AXConstraint(id, type)
            o = o@Exportable(id, type);
        end
        
        function o = subsasgn(o, s, b)
            if strcmp(s(1).type, '.')
                FTSASSERT(length(s)==1, 'Multiple level reference is not allowed');
                subs = s(1).subs;
                FTSASSERT(ischar(subs) && isrow(subs), 'Property name must be a char-type string');
                switch subs
                    case 'priority'
                        FTSASSERT(isnumeric(b) && isscalar(b), 'priority should be an integer number');
                        o.(subs) = b;
                        return;
                    case 'isEnabled'
                        FTSASSERT(isscalar(b) && (islogical(b) || isnumeric(b)), [subs ' should be true or false']);
                        o.(subs) = logical(b);
                        return;
                    case {'desc'}
                        FTSASSERT(isa(b,'char') && isrow(b), [subs ' should be a char-type string']);
                        o.(subs) = b;
                        return;
                    case {'selection'}
                        if ~iscell(b)
                            b = {b};
                        end
                        FTSASSERT(iscell(b) && all(cellfun(@(c) ischar(c),b)), [subs ' should be a cell array of chars']);
                        o.(subs) = b;
                        return;
                    %%% Following passed to containers.Map to process                        
                    case 'UNIT'
                        FTSASSERT(isa(b,'Unit'), 'UNIT should be type of Unit');
                        b = char(b);
                    case 'SCOPE'
                        FTSASSERT(isa(b,'char') && isrow(b), 'SCOPE should be a char-type string');
                        FTSASSERT(ismember(b, o.SCOPES), ['SCOPE should be one of' sprintf(' %s',o.SCOPES{:})]);
                    otherwise
                        FTSASSERT(ismember(subs, keys(o.PROPERTY_MAP)), 'Unrecognized property specified');
                end

                [tf, loc] = ismember(subs, o.pnames);
                if tf  % modify existing one
                    if isempty(b)  % remove one property of the constraint
                        o.pnames(loc)  = [];
                        o.pvalues(loc) = [];
                    else   % modify the property
                        o.pvalues{loc} = b;
                    end
                else   % add a new one
                    o.pnames  = [o.pnames, subs];
                    o.pvalues = [o.pvalues, b];
                end
            else
                o = builtin('subsasgn', o, s, b);
            end
        end
        
        function r = subsref(o, s)
            if strcmp(s(1).type, '.')
                FTSASSERT(length(s)==1, 'Multiple level reference is not allowed');
                subs = s(1).subs;
                FTSASSERT(ischar(subs) && isrow(subs), 'Property name must be a char-type string');
                switch subs
                    case {'isEnabled', 'desc', 'selection', 'priority', 'id', 'type'}
                        r = o.(subs);
                    %%% Following passed to containers.Map to process 
                    case {'properties'}
                        r = o.pnames;
                    otherwise
                        [tf, loc] = ismember(subs, o.pnames);
                        FTSASSERT(tf, ['Property ' subs ' does not exist']);
                        r = o.pvalues(loc);
                end
            else
                r = builtin('subsref', o, s);
            end
        end            
        
        function export(o, strategy)  
            f = str2func(['com.axiomainc.portfolioprecision.optimization.constraints.' o.type]);
            cnst = f(strategy, o.id, o.desc);
            cp = com.axiomainc.portfolioprecision.optimization.constraints.ConstraintProperties();
            csp = com.axiomainc.portfolioprecision.optimization.constraints.ConstraintProperties();
            ptypes = cp.getPropertyTypes();
            sptypes = csp.getPropertyTypes();
            
            for i = 1:length(o.pnames)
                pname = o.pnames{i};
                pval  = o.pvalues{i};
                ptype = o.PROPERTY_MAP(pname);
                pval = getpval(o,cnst,ptype,pval);
                if ptype(1) == ' '
                    cp.setProperty(ptypes.(pname), pval);
                end
            end
            
            cnst.setProperties(cp);
            
            if ~isempty(o.selection) && ...
               isa(cnst, 'com.axiomainc.portfolioprecision.optimization.constraints.SelectionConstraint')  
                for j=1:length(o.selection)
                    csp.clear();
                    for i=1:length(o.pnames)
                        pname = o.pnames{i};
                        pval  = o.pvalues{i};
                        ptype = o.PROPERTY_MAP(pname);
                        pval = getpval(o,cnst,ptype,pval);
                        if ptype(1) == 'S'
                            if ~iscell(pname)
                                pname = {pname};
                            end
                            if ~iscell(pval)
                                pval = {pval};
                            end
                            if ismember(pname,{'MAX_ARRAY','MIN_ARRAY','MAX_VIOLATION_ARRAY','PENALTY_ARRAY'})
                                [~, loc] = ismember(pname,{'MAX_ARRAY','MIN_ARRAY','MAX_VIOLATION_ARRAY','PENALTY_ARRAY'});
                                map = {'MAX','MIN','MAX_VIOLATION','PENALTY'};
                                pname = map(loc);
                                csp.setProperty(sptypes.(pname{:}),pval{:}(j));
                            else
                                csp.setProperty(sptypes.(pname{:}),pval{:});
                            end
                        end
                    end
                    
                    if isempty(char(csp.toString()))
                        csp = csp.EMPTY_PROPERTIES;
                    end

                    st = o.getSelectionType(o.selection{j});
                    switch st
                        case AXSelection.ASSET
                            cnst.addAssetSelection(o.ws.getAsset(o.selection{j}), csp);
                        case AXSelection.GROUP
                            cnst.addGroupSelection(o.ws.getGroup(o.selection{j}), csp);
                        case AXSelection.METAGROUP
                            cnst.addMetagroupSelection(o.ws.getMetagroup(o.selection{j}), csp);
                        case AXSelection.SET
                            cnst.addAssetSetSelection(o.ws.getAssetSet(o.selection{j}), csp);
                        otherwise
                            FTSASSERT(false, ['Invalid selection type for ' o.selection{j}]);
                    end
                end
            end

            cnst.setEnabled(logical(o.isEnabled));
            if o.priority > 0
                ch = strategy.getConstraintHierarchy();
                ch.setPriority(cnst, o.priority);
            end
            %%% cnst.sanityCheck(); % leave it to AXStrategy
            
            function pval = getpval(o,cnst,ptype,pval)
                switch ptype(2:end)
                    case 'Boolean'
                        pval = logical(pval);
                    case 'Integer'
                        pval = int32(pval);
                    case 'Double'
                        pval = double(pval);
                    case 'String'
                    case 'Group'
                        pval = o.ws.getGroup(pval);
                    case 'RiskModel'
                        pval = o.ws.getRiskModel(pval);
                    case 'AlphaUncertaintyModel'
                        pval = o.ws.getAlphaUncertaintyModel(pval);
                    case 'GoldmanSachsShortfallModel'
                        pval = o.ws.getGoldmanSachsShortfallModel(pval);
                    case 'RiskUncertaintyModel'
                        pval = o.ws.getRiskUncertaintyModel(pval);
                    case 'PenaltyType'
                        pval = cnst.getPenaltyTypes().(pval);
                    case 'ScopeType'
                        pval = cnst.getScopeTypes().(pval);
                    otherwise
                        func = str2func([ptype(2:end) '.valueOf']);
                        pval = func(pval);
                end
            end
        end
    end
    
    methods (Static, Access = private)
        function map = initPropertyMap
            cellMap = {...
            'GRANDFATHER_BOUNDS',     ' Boolean', ...
            'BASE_SET',               ' String', ...
            'KAPPA',                  ' Double', ...
            'MAX',                    ' Double', ...
            'MAX_VIOLATION',          ' Double', ...
            'MIN',                    ' Double', ...
            'PENALTY',                ' Double', ...
            'PENALTY_TYPE',           ' PenaltyType', ...
            'WEIGHT',                 'SDouble', ... 
            'TEXT',                   ' String', ...
            'WEIGHTED',               'SBoolean', ...
            'UNIT',                   ' com.axiomainc.portfolioprecision.Unit', ...
            'SCOPE',                  ' ScopeType', ... 
            'BENCHMARK',              ' Group', ...
            'BUY_ATTRIBUTE',          ' Group', ...
            'SELL_ATTRIBUTE',         ' Group', ...
            'ALPHA_UNCERTAINTY_MODEL',' AlphaUncertaintyModel', ...
            'RISKMODEL',              ' RiskModel', ...
            'GS_SHORTFALL_MODEL',     ' GoldmanSachsShortfallModel', ...
            'RISK_UNCERTAINTY_MODEL', ' RiskUncertaintyModel', ...
            'EXCLUDE_CAP_GAINS',      ' Boolean', ...
            'INCLUDE_SHORT_TERM',     ' Boolean', ...
            'INCLUDE_LONG_TERM',      ' Boolean', ...
            'FACTOR_WEIGHT',          ' Double', ...
            'SPECIFIC_WEIGHT',        ' Double', ...
            'USE_BUDGET_VALUE',       ' Boolean', ...
            'ISSUER_THRESHOLD',       ' Double', ...  %???
            'ISSUER_TOTAL_MAX',       ' Double', ...  %???
            'ISSUER_METAGROUP',       ' String', ...
            'SINGLE_ISSUE_SET',       ' String', ...
            'MAX_ARRAY'               'SDouble', ... % for constraint properties in multiselection
            'MIN_ARRAY'               'SDouble', ... % for constraint properties in multiselection
            'PENALTY_ARRAY'           'SDouble', ... % for constraint properties in multiselection
            'MAX_VIOLATION_ARRAY'     'SDouble', ... % for constraint properties in multiselection
            'MIN_VALUES_GROUP',       'SString', ...
            'MAX_VALUES_GROUP',       'SString', ...
            'MIN_VALUES_METAGROUP',   'SString', ...
            'MAX_VALUES_METAGROUP',   'SString', ...
            'QUALIFICATION',          ' String', ...  % ref. to Account or AccountGroup
            'NUM_OF_DAYS',            ' Integer'};
            %'FILE_NAME', ...
            %'FILE_DELIMITER', ...
            %'FILE_ASSETMAP_ID'}, ...
            map = containers.Map(cellMap(1:2:end-1), cellMap(2:2:end));
        end
    end
end
