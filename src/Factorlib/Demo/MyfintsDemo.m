%% Load Item TS

secIds = '';
itemId = 'D000904812';  % Sales
startDate = '';
endDate = '';
Freq = '';
Sales = LoadRawItemTS(secIds,itemId,startDate,endDate);
%Sales = LoadRawItemTS(secIds,itemId,startDate,endDate,Freq,'BusDays',0,'CalcMethod','Exact');

%% Load index holding
aggId = '';
startDate = '';
endDate = '';
Freq = '';
isLive = 0;
[secIds, holdingTS] = LoadIndexHoldingTS(aggId,startDate,endDate,Freq,isLive);
% [secIds, holdingTS] = LoadIndexHoldingTS(aggId,startDate,endDate,Freq,isLive,'BusDays',0,'CalcMethod','Nearest');

%% Load Point-In-Time 
secIds = '';
itemId = 'D002000056';  % BookValue
startDate = '';
endDate = '';
Freq = '';
Qtrs = 4;
bookValue = LoadRawItemPIT(secIds,itemId,startDate,endDate,Qtrs,Freq,'Busday',0,'CalcMethod','nearest');
    