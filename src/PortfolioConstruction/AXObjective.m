classdef AXObjective < Exportable
    properties (Access = private)
        objtermids = {};
        objterms = {};
    end
    
    properties (Dependent, SetAccess = private)
        targetSense
    end
    
    methods
       function o = AXObjective(id, type)
       % type here serves as objective sense role; i.e., either Objective.Target.MAXIMIZE or Objective.Target.MINIMIZE
           o = o@Exportable(id, type);
       end
       
       function s = get.targetSense(o)
           s = o.type;
       end
       
       function o = addExpectedReturnObjective(o, objectiveTermId, alphaGroupId, weight, varargin)
           ot = {'ExpectedReturnObjective', 'GROUP', alphaGroupId, 'WEIGHT', weight};
           o = o.addObjectiveTerm(objectiveTermId, ot, varargin{:});
       end

       function o = addLinearShortObjective(o, objectiveTermId, shortCostGroupId, weight, varargin)
           ot = {'LinearShortObjective', 'GROUP', shortCostGroupId, 'WEIGHT', weight};
           o = o.addObjectiveTerm(objectiveTermId, ot, varargin{:});
       end
       
       function o = addLinearShortSellObjective(o, objectiveTermId, shortSellCostGroupId, weight, varargin) 
           ot = {'LinearShortSellObjective', 'GROUP', shortSellCostGroupId, 'WEIGHT', weight};
           o = o.addObjectiveTerm(objectiveTermId, ot, varargin{:});
       end
       
       function o = addMarketImpactObjective(o, objectiveTermId, buyImpactGroupId, sellImpactGroupId, marketImpactTypeStr, weight, varargin)
           miTypes = {'FIVE_THIRDS_POWER', 'QUADRATIC',  'THREE_HALVES_POWER'};
           FTSASSERT(ismember(makretImpactTypeStr, miTypes), ['marketImpactType must be one of' sprintd(' %s', miTypes{:})]);
           ot = {'MarketImpactObjective', 'GROUP', buyImpactGroupId, 'GROUP', sellImpactGroupId, ...
                 'com.axiomainc.portfolioprecision.optimization.objectives.MarketImpactType', marketImpactTypeStr, ... 
                 'WEIGHT', weight};
           o = o.addObjectiveTerm(objectiveTermId, ot, varargin{:});
       end
       
       function o = addRiskAlphaFactorObjective(o, objectiveTermId, benchmarkGroupId, riskModelId, alphaFactorVol, weight, varargin)
           ot = {'RiskAlphaFactorObjective', 'GROUP', benchmarkGroupId, 'RISKMODEL', riskModelId, ...
                 'DOUBLE', alphaFactorVol, 'WEIGHT', weight};
           o = o.addObjectiveTerm(objectiveTermId, ot, varargin{:});
       end
       
       function o = addRiskObjective(o, objectiveTermId, benchmarkGroupId, riskModelId, weight, varargin) 
           ot = {'RiskObjective', 'GROUP', benchmarkGroupId, 'RISKMODEL', riskModelId, 'WEIGHT', weight};
           o = o.addObjectiveTerm(objectiveTermId, ot, varargin{:});
       end
       
       function o = addRobust(o, objectiveTermId, alphaGroupId, kappa, riskModelId, weight, varargin) 
           ot = {'Robust', 'GROUP', alphaGroupId, 'DOUBLE', kappa, 'RISKMODEL', riskModelId, 'WEIGHT', weight};
           o = o.addObjectiveTerm(objectiveTermId, ot, varargin{:});
       end
       
       function o = addTransactionCostObjective(o, objectiveTermId, weight, varargin)
           ot = {'TransactionCostObjective', 'WEIGHT', weight};
           o = o.addObjectiveTerm(objectiveTermId, ot, varargin{:});
       end

       function o = addVarianceAlphaFactorObjective(o, objectiveTermId, benchmarkGroupId, riskModelId, alphaFactorVol, weight, varargin) 
           ot = {'VarianceAlphaFactorObjective', 'GROUP', benchmarkGroupId, 'RISKMODEL', riskModelId, ...
                 'DOUBLE', alphaFactorVol, 'WEIGHT', weight};
           o = o.addObjectiveTerm(objectiveTermId, ot, varargin{:});
       end
       
       function o = addVarianceObjective(o, objectiveTermId, benchmarkGroupId, riskModelId, weight, varargin) 
           ot = {'VarianceObjective', 'GROUP', benchmarkGroupId, 'RISKMODEL', riskModelId, 'WEIGHT', weight};
           o = o.addObjectiveTerm(objectiveTermId, ot, varargin{:});
       end
       
       function export(o, strategy)
           if isempty(o.objtermids)
               TRACE.Warn('AXObjective:export', 'No objective terms created');
               return;
           end
           
           obj = com.axiomainc.portfolioprecision.optimization.Objective(strategy, o.id, o.id);
           target = obj.getTarget();
           obj.setTarget(target.valueOf(o.targetSense));

           for n = 1:length(o.objtermids)
               id = o.objtermids{n};
               objectiveTerm = o.objterms{n};
               priority = objectiveTerm{end};
               objectiveTerm(end) = [];
               f = str2func(['com.axiomainc.portfolioprecision.optimization.objectives.ObjectiveTermUtils.create' objectiveTerm{1} 'Term']);
               for i = 2:2:length(objectiveTerm)
                   switch upper(objectiveTerm{i})
                       case {'GROUP', 'BENCHMARK'}
                           objectiveTerm{i+1} = o.ws.getGroup(objectiveTerm{i+1});
                       case {'DOUBLE', 'WEIGHT'}
                       case 'RISKMODEL'
                           objectiveTerm{i+1} = o.ws.getRiskModel(objectiveTerm{i+1});
                       otherwise
                           f = str2func([objectiveTerm{i} '.valueOf']);
                           objectiveTerm{i+1} = f(objectiveTerm{i+1});
                   end
               end
               f(strategy, id, objectiveTerm{3:2:end});
               if priority > 0
                   oh = strategy.getObjectiveHierarchy();
                   oh.setPriority(strategy.getObjectiveTerm(id), priority);
               end
           end
       end
   end
   
   methods (Access = private)
       function o = addObjectiveTerm(o, objectiveTermId, objectiveTerm, priority)
           if nargin < 4, priority = 0; end
           objectiveTerm = [objectiveTerm priority];
           
           [tf, loc] = ismember(objectiveTermId, o.objtermids);
           if tf
               o.objterms(loc) = objtectiveTerm;
           else
               o.objtermids = [o.objtermids; objectiveTermId];
               o.objterms = [o.objterms; {objectiveTerm}];
           end
       end
   end
end
