% This function loads the neccessary data for backtest - benchmark holdings,
% signals (alpha), GICS, prices in USD, ADV, forward total return and(or)
% starting portfolio holding

function LoadData(filename, signal, aggid, startdate, enddate, freq, lqaggid, startpf)

% set default freqency to be monthly
if ~exist('freq', 'var')
    freq = 'M';
end

% Load the universe data
if isa(aggid, 'myfints')
    bmhd = aggid;
    secid = FieldId2QuantId(fieldnames(bmhd, 1));
    bmhd = aligndates(bmhd, freq);
else
    [secid, bmhd] = LoadIndexHoldingTS(aggid, startdate, enddate, 0, freq);
end

if exist('startpf', 'var')
    [bmhd, startpf] = alignfields(bmhd, startpf, 'union');
    secid = FieldId2QuantId(fieldnames(bmhd,1));
end
if exist('lqaggid', 'var')
    [~, liquidhd] = LoadIndexHoldingTS(lqaggid, startdate, enddate, 0, freq);
end
gics = LoadQSSecTS(secid, '913', 0, startdate, enddate, freq);
switch freq
    case 'A'
        fwddate = datestr(addtodate(datenum(enddate),1,'Y'), 'yyyy-mm-dd');
%     case 'S'
%         fwddate = datestr(addtodate(datenum(enddate),6,'M'), 'yyyy-mm-dd');
    case 'Q'
        fwddate = datestr(addtodate(datenum(enddate),3,'M'), 'yyyy-mm-dd');
    case 'M'
        fwddate = datestr(addtodate(datenum(enddate),1,'M'), 'yyyy-mm-dd');
    case 'W'
        fwddate = datestr(addtodate(datenum(enddate),7,'D'), 'yyyy-mm-dd');
    otherwise
        error('the input frequency is not supported in this version, please input one of the following: A, Q, M, W')
end
TRI = LoadRawItemTS(secid, 'D001410446', startdate, fwddate, freq);
price = LoadRawItemTS(secid, 'D001410415', startdate, enddate, freq);
adv = LoadRawItemTS(secid, 'D001415475', startdate, enddate, freq); % volume is daily in order to calculate the ADV
%     volume = LoadRawItemTS(secid, 'D001410431', startdate, enddate); % volume is daily in order to calculate the ADV
%     adv = aligndates(ftsmovavg(volume,21,1), freq);

totret = Price2Return(TRI,1);
fwdret = leadts(totret,1);
fwdret(end,:) = [];

% Load the signal
if ischar(signal)
    signal = LoadFactorTS(secid, signal, startdate, enddate, 0, freq); % if it is a string, treat it as a factorid of data stored in factorTS
    [signal, gics, bmhd] = aligndata(signal, gics, bmhd);
    signal = normalize(signal, 'method', 'norminv', 'weight', bmhd, 'gics', gics);
else 
    assert(isa(signal, 'myfints'), 'the input signal is neither a string nor a myfints');
end

% align data 
if exist('adv','var')
    [bmhd, signal, fwdret, gics, price, adv] = aligndata(bmhd, signal, fwdret, gics, price, adv, fwdret.dates, 'union');
else
    [bmhd, signal, fwdret, gics, price] = aligndata(bmhd, signal, fwdret, gics, price, fwdret.dates, 'union');
end

if exist('liquidhd','var')
    liquidhd(:, ~ismember(fieldnames(liquidhd,1), fieldnames(bmhd,1))) = [];
    [bmhd, liquidhd] = aligndata(bmhd, liquidhd, 'union', bmhd.dates);
end

if exist('startpf', 'var')
    [bmhd, startpf] = alignfields(bmhd, startpf);
end

% backfill for possible non-daily items
bmhd = backfill(bmhd,inf,'row');
signal = backfill(signal,inf,'row');
gics = backfill(gics,inf,'row');

% load static attributes of stocks after all the myfints are aligned
secid = FieldId2QuantId(fieldnames(bmhd,1));
ctry = LoadSecInfo(secid, 'country', startdate, enddate, 0);
ctry = ctry.country;

variables = who;
variables(ismember(variables, {'variables','startdate', 'enddate', 'fwddate', 'TRI', 'totret', 'filename', 'volume', 'aggid', 'secid'}')) = [];

save(filename, variables{:});    
% save(filename,'bmhd','signal','fwdret','price','gics','adv');

return






