%% Script to massively populate factor values to FactorTS_BT and FactorTS_Live
% function PopFactor(aggId, startDate, endDate, isLive)

isLive     = 1;
isUpdateDB = 1;
startDate  = '2010-12-31';
endDate    = '2011-12-31';
targetFreq = 'M';
aggId      = {'00053'}; %,'000524248'} %,'000530824'};
%aggId      = {'0064106233','0064891800','0064990100'};
% factorIds(ismember(factorIds, ...
%     {'F00221','F00222','F00223','F00224','F00225','F00226'})) = [];
% factorIds(ismember(factorIds, ...
%     {'F00048','F00049','F00050','F00051','F00083','F00084','F00085','F00034'})) = []; 

% exclude RIM, RESINCM, Short Interest, COMOVE, STATARB for global stocks

factorIds = runSP('QuantStrategy','fac.getFactorIdList',{0});
factorIds = factorIds.Id;

nFactor = length(numel(factorIds));
success = zeros(nFactor,1);
factors = cell(nFactor,1);
reasons = cell(nFactor,1);

if isLive
    args = {endDate};
else
    args = {startDate, endDate, targetFreq};
end

for i = 1:nFactor
    [factors{i}, success(i), reasons{i}] = Factory.RunRegistered(factorIds(i), aggId, isUpdateDB, isLive, args{:});
end
