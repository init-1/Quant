function parameter = LoadAXParameter(isshort,isactive,objective,weight,budgetsize,varargin)

parameter = Defaults.parameter(isshort,isactive);

% Input params
inputparam = varargin(1:4:end-3);
inputvalue = varargin(2:4:end-2);
inputvio = varargin(3:4:end-1);
inputpriority = varargin(4:4:end);

% Default for objective
if exist('objective','var')
    parameter.objective.name = objective;
    assert(~isempty(objective) && ischar(objective),'Objective must be a string.');
end

if exist('weight','var')
    parameter.objective.weight = weight;
    assert(~isempty(weight) && isnumeric(weight),'Objective Weight must be a number.');
end

if exist('budgetsize','var')
    parameter.budgetsize = budgetsize;
    assert(~isempty(budgetsize) && isnumeric(budgetsize),'Budget Size must be a number.');
else
    parameter.budgetsize = NaN;
end

fn = fieldnames(parameter);
fn(ismember(fn,{'objective'})) = [];

% Display illegal parameter names detected
if ~isempty(inputparam(~ismember(inputparam,fn)))
    illegal = inputparam(ismember(inputparam,fn));
    warning(['The following parameter(s) are illegal and will not be used:',sprintf(' %s',illegal{:}) '.']);
end

% Assign Parameter Value
for i=1:length(inputparam)
    switch lower(inputparam{i})
        case {'minholding','mintrade','actbeta','budget'}
            val = inputvalue{i};
            pri = inputpriority{i};
            if ~isempty(val)
                parameter.(inputparam{i}).value = val;
                parameter.(inputparam{i}).priority = pri;
            end
            assert(isnumeric(val) && val >= 0,['Value for ',inputparam{i},' has to be numeric.']);
        otherwise
            val = inputvalue{i};
            vio = inputvio{i};
            pri = inputpriority{i};
            if ~isempty(val)
                if strcmpi(inputparam{i},'name')
                    if numel(val) ~= 2
                        warning(['Invalid constraint for Name. 2x1 array required for min and max. Using default...']);
                    else
                        parameter.(inputparam{i}).value = val;
                        parameter.(inputparam{i}).maxviolation = vio;
                        parameter.(inputparam{i}).priority = pri;
                    end
                else
                    parameter.(inputparam{i}).value = val;
                    parameter.(inputparam{i}).maxviolation = vio;
                    parameter.(inputparam{i}).priority = pri;
                end                
                assert(isnumeric(val) && all(val >= 0),['Value for ',inputparam{i},' has to be numeric.']);
                assert(isnumeric(vio) && vio >= 0, ['Max Violation for ',inputparam{i},' has to be numeric.']);
                assert(isnumeric(pri) && pri >= 0, ['Priority for ',inputparam{i},' has to be numeric.']);
            end
    end
end

end