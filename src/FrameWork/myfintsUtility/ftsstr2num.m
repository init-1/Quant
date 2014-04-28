function [xtsnum, r] = ftsstr2num(xtsstr)
    %maps a string xts/myfints into numbers myfints
    if ~iscell(fts2mat(xtsstr))
        xtsnum = xtsstr;
        return;
    end
    
    datastr = fts2mat(xtsstr);
    fn = fieldnames(xtsstr,1);
    dates = xtsstr.dates;

    r = unique(datastr);
    r = r(~cellfun(@(c) any(isnan(c)),r));
    
    datanum = nan(size(datastr));
    for i=1:numel(r)
        idx = (strcmp(datastr,r{i}));
        datanum(idx) = i;
    end
    
    if isa(xtsstr,'myfints')
        xtsnum = myfints(dates,datanum,fn);
    else
        xtsnum = xts(dates,datanum,fn);
    end
end