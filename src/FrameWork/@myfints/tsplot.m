function h = tsplot(fts, varargin)
o.dateformat = 'mmm yyyy';
s = warning('query' ,'VAROPTION:UNRECOG');
warning('off', 'VAROPTION:UNRECOG');
o = Option.vararginOption(o, fieldnames(o), varargin{:});
warning(s.state, 'VAROPTION:UNRECOG');
dates  = fts.dates;
x = 1:length(dates);
if isempty(o.dateformat)
    dstr = datestr(dates, '     mmm');
    idx = month(dates) == 1;
    dstr(idx,:) = datestr(dates(idx), '\\bf yyyy');
else
    dstr = datestr(dates, o.dateformat);
end
h = tsplot(x, fts2mat(fts), 'xticklabels', dstr, o.varargin{:});
end
