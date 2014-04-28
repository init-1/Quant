classdef AXStrategy < Exportable
    properties
        DBID = NaN;  % related to database, double; if no DB involved, just ignore it
        
        isObjectiveHierarchy = false;
        isConstraintHierarchy = false;
        isAllowCrossover = false;
        isAllowGrandfathering = false;
        isAllowShorting = false;
        isIgnoreCompliance = false;
        isIgnoreRoundLots = false;
        included = {'MASTER'};  % if there's a empty string in it, then the old local universe will be cleared first
        excluded = {};
%         isMarketNeutral = false;  % not belongs to axioma Strategy; from Jeremy code
        objective = [];
        constraints = [];
    end
    
    methods
        function o = AXStrategy(id, varargin)
            % Process strategy options
            o = o@Exportable(id, 'Strategy');
            flds = varargin(1:2:end-1);
            vals = varargin(2:2:end);
            for i = 1:length(flds)
                o.(flds{i}) = vals{i};
            end
            
            if ~o.isAllowShorting && o.isAllowCrossover
                TRACE.Warn('    Strategy option ''isAllowCrossover'' is ineffective\n');
                o.isAllowCrossover = false;
            end
            if ischar(o.included), o.included = {o.included}; end
            if ischar(o.excluded), o.excluded = {o.excluded}; end
        end
        
        function export(o)
            % Do the real thing on Axioma side
            str = o.ws.getStrategy(o.id);
            if isempty(str)
                TRACE(['    Creating Strategy ' o.id ' ... ']);
                str = com.axiomainc.portfolioprecision.optimization.Strategy(o.ws, o.id, o.id, o.ws.getDate());
                TRACE('done\n');
            else
                TRACE(['    Strategy ' o.id ' already exists\n']);
            end
            
            str.setAllowCrossover(logical(o.isAllowCrossover));
            str.setAllowGrandfathering(logical(o.isAllowGrandfathering));
            str.setAllowShorting(logical(o.isAllowShorting));
            str.setIgnoreCompliance(logical(o.isIgnoreCompliance));
            str.setIgnoreRoundLots(logical(o.isIgnoreRoundLots));
            
            oh = str.getObjectiveHierarchy();
            oh.setEnabled(logical(o.isObjectiveHierarchy));
            ch = str.getConstraintHierarchy();
            ch.setEnabled(logical(o.isConstraintHierarchy));
            
            lu = str.getLocalUniverse();
            lu.reset();
            for idc = o.included(:)'  % just make sure it's a row vector
                id = idc{:};
                switch o.getSelectionType(id)
                    case AXSelection.ASSET
                        lu.includeAsset(o.ws.getAsset(id));
                    case AXSelection.GROUP
                        lu.includeGroup(o.ws.getGroup(id));
                    case AXSelection.METAGROUP
                        lu.includeMetagroup(o.ws.getMetagroup(id));
                    case AXSelection.SET
                        lu.includeAssetSet(o.ws.getAssetSet(id));
                    otherwise
                        FTSASSERT(false, ['Invalid selection type for ' id]);
                end
            end
            
            for idc = o.excluded(:)'  % just make sure it's a row vector
                id = idc{:};
                switch o.getSelectionType(id)
                    case AXSelection.ASSET
                        lu.excludeAsset(o.ws.getAsset(id));
                    case AXSelection.GROUP
                        lu.excludeGroup(o.ws.getGroup(id));
                    case AXSelection.METAGROUP
                        lu.excludeMetagroup(o.ws.getMetagroup(id));
                    case AXSelection.SET
                        lu.excludeAssetSet(o.ws.getAssetSet(id));
                end
            end
            
            % Note that set o.strategy should before export() because export() depends on current strategy settings
            if isa(o.objective, 'AXObjective')
                export(o.objective, str);
                str.setActiveObjective(str.getObjective(o.objective.id));
            end
            
            for i = 1:length(o.constraints)
                export(o.constraints{i}, str);
            end
            
            str.sanityCheck(false);
        end
    end
    
end