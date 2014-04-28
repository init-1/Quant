% parameter
strategyid = 'FAC_MSCI_WORLDHCV2';
startdate = '2012-01-01';
enddate = '2012-08-09';
isprod = 1;

%StrategyResult_1 = Main_Attribution(strategyid, startdate, enddate, 'isprod', isprod, 'method', 'signalPF'); % signal portfolio based attribtution method
StrategyResult_2 = Main_Attribution(strategyid, startdate, enddate, 'isprod', isprod, 'method', 'uniReg'); % univariate regression base attribution method


% % get customized result
% StrategyResult = ResultBetweenDates(StrategyResult, '2010-12-31', '2011-12-30', 'Y2011'); 
% StrategyResult = ResultBetweenDates(StrategyResult, '2012-04-30', '2012-05-31', 'May2012'); 
% StrategyResult = ResultBetweenDates(StrategyResult, '2007-12-31', '2008-12-30', 'Y2008'); 
% StrategyResult = ResultBetweenDates(StrategyResult, '2003-12-31', '2004-12-30', 'Y2004'); 

savepath = 'Y:\Louis.Luo\QuantStrategy\Analytics\Utility\PerformanceAttribution\Report\';
dateStr = datestr(datenum(enddate),'yyyymmdd');

% % generate attribution reports for signalPF method: 
for i = 1:2
     GenAttributionReport(StrategyResult_1,'ITD','method','signalPF','filename',[savepath, strategyid,'_',dateStr,'(ITD)']); 
%      GenAttributionReport(StrategyResult_1,'YTD','method','signalPF','filename',[savepath, strategyid,'_',dateStr,'(YTD)']); 
%      GenAttributionReport(StrategyResult_1,'MTD','method','signalPF','filename',[savepath, strategyid,'_',dateStr,'(MTD)']); 
end

% % generate attribution reports for uniReg method:
for i = 1:2
     GenAttributionReport(StrategyResult_2,'ITD','method','uniReg','filename',[savepath, strategyid,'_',dateStr,'(ITD)']); 
%      GenAttributionReport(StrategyResult_2,'YTD','method','uniReg','filename',[savepath, strategyid,'_',dateStr,'(YTD)']); 
%      GenAttributionReport(StrategyResult_2,'MTD','method','uniReg','filename',[savepath, strategyid,'_',dateStr,'(MTD)']); 
end

% % generate stock summary reports for uniReg method only: 
for i = 1:2
     GenStockReport(StrategyResult_2,'ITD',[savepath, strategyid,'_StockSummary_',dateStr,'(ITD)']); 
     GenStockReport(StrategyResult_2,'YTD',[savepath, strategyid,'_StockSummary_',dateStr,'(MTD)']); 
     GenStockReport(StrategyResult_2,'YTD',[savepath, strategyid,'_StockSummary_',dateStr,'(MTD)']); 
end

% % generate individual stock detail report for further investigation: 
secid = '0058@';
Investigate(StrategyResult_2, 'YTD', secid);


