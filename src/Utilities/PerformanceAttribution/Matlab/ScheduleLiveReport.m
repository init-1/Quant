function StrategyResult = ScheduleLiveReport(enddate, varargin)

option.method = 'singalPF'; %uniReg
option.period = {'YTD','QTD','MTD','WTD','ITD'};
option.strategyid = {'FAC_SP500','FAC_MSCI_WORLDV2','FAC_MSCI_EAFEV2','FAC_APHD','FAC_MSCI_WORLDHCV2','MFS_EURSC','ADM_SP500'};
option = Option.vararginOption(option, {'method','period','strategyid'}, varargin{:});

startdate = '2010-04-01';
isprod = 1;
dateString = datestr(datenum(enddate),'yyyymmdd');
Path = ['Y:\Louis.Luo\QuantStrategy\Analytics\Utility\PerformanceAttribution\Report\',dateString,'\'];

if ~exist(Path,'dir')
    mkdir(Path);
end

set(0, 'DefaultFigureVisible', 'off');
StrategyResult = cell(size(option.strategyid));
for i = 1:numel(option.strategyid)
    StrategyResult{i} = Main_Attribution(option.strategyid{i}, startdate, enddate, 'isprod', isprod, 'method', option.method);
    for j = 1:numel(option.period)
        GenAttributionReport(StrategyResult{i},option.period{j},'filename',[Path,option.strategyid{i},'_',dateString,'_',option.method,'(',option.period{j},')'],'method',option.method);
        GenAttributionReport(StrategyResult{i},option.period{j},'filename',[Path,option.strategyid{i},'_',dateString,'_',option.method,'(',option.period{j},')'],'method',option.method);
    end
end

if strcmpi(option.method, 'uniReg')
    for i = 1:numel(StrategyResult)
        GenStockReport(StrategyResult{i}, 'YTD', [Path,'StockSummary',StrategyResult{i}.strategyid,'_',dateString,'_(YTD)']);
    end
end

end