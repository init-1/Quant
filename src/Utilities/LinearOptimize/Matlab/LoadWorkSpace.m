% this function loads the required variables from the .mat file and the parameter structure, 
% does neccessary check on the data, and generates constraints according to
% inputs. The optional variables passed in are user-defined asset level
% constraints and attribute level constraints

function [bmhd,signal,fwdret,price,freq,startpf,assetcons,attributecons] = LoadWorkSpace(data, parameter, varargin)

%% Step 1 - Check the data in .mat file
load(data); % data is a .mat file containing required variables for backtest
requiredvar = {'bmhd','signal','fwdret','price','gics','ctry','freq'};
optionalvar = {'adv','startpf','liquidhd'};
for i = 1:numel(requiredvar)
    assert(exist(requiredvar{i}, 'var') == 1, ['required variable: ',requiredvar{i},' does not exist in the provided workspace file']);
end
assert(isaligneddata(bmhd, signal, fwdret, gics, price), 'data in bmhd, signal, fwdret, or price are not aligned');

if exist(optionalvar{1},'var')
    assert(isaligneddata(bmhd, adv), 'data in adv is not aligned with other variables');
end
if exist(optionalvar{2},'var')
    assert(isequal(fieldnames(bmhd,1), fieldnames(startpf,1)), 'stocks in bmhd and startpf are not aligned');
else
    startpf = [];
end



%% Step 2 - Check the data in parameters structure
requiredpara = {'pickup','actbet','tradetoadv','holdtoadv','capital','tcost','sectorbet','sectorlevel','ctrybet','maxto','propactbet','tailactbet'};
existingpara = fieldnames(parameter);
for i = 1:numel(requiredpara)
    assert(ismember(requiredpara(i), existingpara) == 1, ['required parameter: ',requiredpara{i},' does not exist in the provided parameter struct']);
end




%% Step 3 - Build Constraints
% customize the asset level constraints
if numel(varargin) > 0
    assetcons = varargin{1};
    assert(iscell(assetcons) | isequal(assetcons, []), 'the input asset level constraint has to be a cell array or an empty vector');
else
    assetcons = [];
end
assetcons = [assetcons, ConstraintBuilder('LongOnly', bmhd)];
switch parameter.propactbet
    case ''
        assetcons = [assetcons, ConstraintBuilder('ActiveBet', bmhd, parameter.actbet)];
    otherwise
        assetcons = [assetcons, ConstraintBuilder('PropActBet', bmhd, eval(parameter.propactbet), parameter.actbet)];
end
if exist(optionalvar{1},'var')
    assetcons = [assetcons, ConstraintBuilder('TradingLiquidity', adv, parameter.tradetoadv)];
    assetcons = [assetcons, ConstraintBuilder('HoldingLiquidity', adv, parameter.holdtoadv)];
end
if exist(optionalvar{3},'var')
    assetcons = [assetcons, ConstraintBuilder('BenchmarkTail', bmhd, liquidhd, parameter.tailactbet)];
end

% customize the attribute level constraints
if numel(varargin) > 1
    attributecons = varargin{2};
    assert(iscell(attributecons) | isequal(attributecons, []), 'the input attribute level constraint has to be a cell array');
else
    attributecons = [];
end
attributecons = [attributecons, ConstraintBuilder('SumToOne', bmhd)];
attributecons = [attributecons, ConstraintBuilder('SectorNeutral', bmhd, gics, parameter.sectorbet, parameter.sectorlevel)];
attributecons = [attributecons, ConstraintBuilder('CtryNeutral', bmhd, ctry, parameter.ctrybet)];



%% Step 4 - Check whether all the constraints are aligned with original data
myfintsA = cell(numel(attributecons),1);
for i = 1:numel(attributecons)
    myfintsA{i} = attributecons{i}.A;
end
assert(isaligneddata(bmhd, myfintsA{:}), 'data in attribute constraints are not aligned with bmhd');

myfintsB = cell(numel(assetcons),2);
for i = 1:numel(assetcons)
    myfintsB{i,1} = assetcons{i}.ub;
    myfintsB{i,2} = assetcons{i}.lb;
end
assert(isaligneddata(bmhd, myfintsB{:,1}, myfintsB{:,2}), 'data in asset constraints are not aligned with bmhd');

% save(data,'bmhd','signal','fwdret','price','gics','adv','pickup','capital','tcost','assetcons','attributecons');

return