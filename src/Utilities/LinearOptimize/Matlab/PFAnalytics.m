% this function calculate key analytics for the constructed portfolio 

function analytics = PFAnalytics(portfolio, bmhd, signal, fwdret, tcost, freq)

switch freq
    case 'A'
        multip = 1;
%     case 'S'
%         multip = 2;
    case 'Q'
        multip = 4;
    case 'M'
        multip = 12;
    case 'W'
        multip = 52;
    otherwise
        error('the input frequency is not supported in this version, please input one of the following: A, S, Q, M, W')
end

inihd = portfolio.inihd;
opthd = portfolio.opthd;
tradeshr = portfolio.tradeshr;
acthd = opthd - bmhd;

signal(isnan(fts2mat(bmhd)) | fts2mat(bmhd) <= 0) = NaN;

analytics.TO = cssum(abs(inihd - opthd)); % turnover
analytics.pftcost = tcost*analytics.TO; % portfolio transaction cost
analytics.actret = bsxfun(@minus, cssum((acthd).*fwdret), analytics.pftcost); % after cost active return
analytics.cumret = ftsmovsum(analytics.actret,inf,1); % cummulative active return
% analytics.actdrawdown = tsdrawdown(analytics.actret);
analytics.IC = csrankcorr(signal, fwdret);
analytics.TC = csrankcorr(signal, acthd);
analytics.signalexp = cssum(signal.*acthd);
analytics.activeness = cssum(abs(opthd - bmhd))/2;
analytics.nlong = cssum(opthd > 0); % number of long position
analytics.ntrade = cssum(tradeshr ~= 0); % number of trades
analytics.autocorr = csrankcorr(signal, lagts(signal));
analytics.drawdown = FtsDrawDown(analytics.actret);
analytics.yearlyreturn = toannual(analytics.actret,'CalcMethod','CumSum','busdays',0);
yearlydates = analytics.yearlyreturn.dates;
yearlydates(end) = analytics.actret.dates(end);
analytics.yearlyreturn = aligndates(analytics.yearlyreturn, yearlydates);

% scalar result
analytics.annual_ret = nanmean(fts2mat(analytics.actret))*multip;
analytics.annual_vol = nanstd(fts2mat(analytics.actret))*sqrt(multip);
analytics.IR = analytics.annual_ret/analytics.annual_vol;
analytics.avg_TO = nanmean(fts2mat(analytics.TO));
analytics.avg_TC = nanmean(fts2mat(analytics.TC));
analytics.avg_IC = nanmean(fts2mat(analytics.IC));
analytics.std_IC = nanstd(fts2mat(analytics.IC));
analytics.IR_IC = analytics.avg_IC/analytics.std_IC;
analytics.avg_exp = nanmean(fts2mat(analytics.signalexp));
analytics.avg_active = nanmean(fts2mat(analytics.activeness));
analytics.avg_n = nanmean(fts2mat(analytics.nlong));
analytics.avg_ntrade = nanmean(fts2mat(analytics.ntrade));

analytics.avg_acorr = nanmean(fts2mat(analytics.autocorr));
analytics.max_DD = nanmin(fts2mat(analytics.drawdown));


return