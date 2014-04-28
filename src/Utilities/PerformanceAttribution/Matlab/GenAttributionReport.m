function GenAttributionReport(StrategyResult, Period, varargin)
% this function generates attribution report using the input calculation result
option.filename = [StrategyResult.strategyid,'_Report'];
option.method = 'signalPF';
option = Option.vararginOption(option, {'filename','method'}, varargin{:});

set(0, 'DefaultFigureVisible', 'off');

switch lower(option.method)
    case 'signalpf'
        GenSignalPFReport(StrategyResult, Period, option.filename);
    case 'unireg'
        GenUniRegReport(StrategyResult, Period, option.filename);
    otherwise
        error(['Invalid attribution method: ',option.method]);
end

set(0, 'DefaultFigureVisible', 'on');

end