 function o = CalcPeriodStatistics(o, varargin)
    option.window = 3;
    option.suffix = '3M';
    option.startdate = [];
    option.enddate = [];

    option = Option.vararginOption(option, {'window','suffix','startdate','enddate'}, varargin{:});

    Field_To_Sample_Style = {'factor_neutral','LS','Long','Short','IC'};
    Field_To_Sample_nonStyle = {'autocorr','coverage','nonezero', 'liquidrtn', 'dispersion', 'meanfacval', 'medianfacval'};
    Field_To_Copy = {'facname','neutralstyle','regimename'};
    
    switch upper(o.freq)
        case 'W'
            ann_adj = 52;
        case 'M'
            ann_adj = 12;
        case 'Q'
            ann_adj = 4;
        case 'D'
            ann_adj = 252;
        otherwise
            error('invalid frequency inputed');
    end

    dates = o.bmhd.dates;
    facname = cell(1,numel(o.statistics));

    for i = 1:numel(o.statistics)
        facname{i} = o.statistics{i}.facname;
    end

    nFactor = numel(o.statistics);
    sample_idx = zeros(length(dates),1);
    option.enddate = datestr(dates(end),'yyyy-mm-dd');

    if ~isempty(option.startdate)
        sample_idx(dates >= datenum(option.startdate) & dates <= datenum(option.enddate)) = 1;
    else
        sample_idx(end-option.window+1:end) = 1;
    end
    sample_idx = logical(sample_idx);
    cellstruct = cell(nFactor,1);
    tempstat = struct();

    tempstat.window = option.window;
    tempstat.startdate = option.startdate;
    tempstat.enddate = option.enddate;

    for i = 1:nFactor
        nstyle = numel(o.statistics{i}.neutralstyle);
        for k = 1: numel(Field_To_Sample_Style)
            for n = 1:nstyle
                tempstat.(Field_To_Sample_Style{k}){n} = o.statistics{i}.(Field_To_Sample_Style{k}){n}(sample_idx,:);
            end
        end
        for k = 1: numel(Field_To_Sample_nonStyle)
            tempstat.(Field_To_Sample_nonStyle{k}) = o.statistics{i}.(Field_To_Sample_nonStyle{k})(sample_idx,:);
        end
        for k = 1: numel(Field_To_Copy)
            tempstat.(Field_To_Copy{k}) = o.statistics{i}.(Field_To_Copy{k});
        end
        %field to recalculate
        for n = 1:nstyle
            tempstat.IRLS(n) = nanmean(tempstat.LS{n})./nanstd(tempstat.LS{n})*sqrt(ann_adj);
            tempstat.IRIC(n) = nanmean(tempstat.IC{n})./nanstd(tempstat.IC{n})*sqrt(ann_adj);
        end
        cellstruct{i} = tempstat;
    end

    storeResult = struct();
    storeResult.name = ['statistics_' option.suffix];
    storeResult.statistics = cellstruct;    
    
    %Check whether stats already exist with the same name    
    if isfield(o,'periodstatistics')
        statsname = cellfun(@(x){x.name}, o.periodstatistics);    
        locidx = find(ismember(statsname,storeResult.name));    
        if isempty(locidx)
            o.periodstatistics{numel(o.periodstatistics)+1} = storeResult;
        else
            o.periodstatistics{locidx} = storeResult;
        end
    else
        o.periodstatistics{1} = storeResult;
    end
    
end % of function