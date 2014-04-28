% This function loads parameters for backtest and output a structure

function parameter = LoadParameter(varargin)

% Default parameter values
paramname = {'pickup', 'actbet', 'tradetoadv', 'holdtoadv', 'capital', ...
   'tcost', 'sectorbet', 'sectorlevel', 'ctrybet', 'maxto', 'tailactbet', 'propactbet'};
defaultvalue = {0.2, 0.005, Inf, Inf, 100000000, 0, 0.005, 1, Inf, 0.2, 0, ''};

% Input params
inputparam = varargin(1:2:end-1);
inputvalue = varargin(2:2:end);

% display illegal parameter names detected
if ~isempty(inputparam(~ismember(inputparam,paramname)))
    illegal = inputparam(~ismember(inputparam,paramname));
    warning(['following parameter names are illegal and will not be used:',sprintf(' %s',illegal{:})]);
end

% assign parameter value
for i = 1:numel(paramname)
    parameter.(paramname{i}) = inputvalue{ismember(inputparam, paramname(i))};
    if isempty(parameter.(paramname{i}))
        parameter.(paramname{i}) = defaultvalue{i};
    end
    if i < numel(paramname)
        assert(isnumeric(parameter.(paramname{i})), ['parameter: ',paramname{i},' has to be numeric']);
        assert(parameter.(paramname{i}) >= 0, ['parameter: ',paramname{i},' cannot be negative']);
    else
        assert(ischar(parameter.(paramname{i})), ['parameter: ',paramname{i},' has to be a string']);
    end
end

return