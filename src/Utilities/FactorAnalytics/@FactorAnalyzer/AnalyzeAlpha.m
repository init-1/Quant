function result = AnalyzeAlpha(o, varargin)
    option.faclist = o.facinfo.name;        
    option.normdata = o.gics;
    option.normlevel   = 1;
    option.wgtmethod   = 'EW';
    option.window = 24;
    option.facgrp = {[1:numel(o.factorts)]};

    option = Option.vararginOption(option, {'faclist','normdata','excludesector','normlevel','wgtmethod','window','facgrp'}, varargin{:});
    activeidx = ismember(o.facinfo.name, option.faclist);
    ishighthebetter = o.facinfo.ishigh(activeidx);
    facts = o.factorts(activeidx);

    nfactor = numel(facts);
    facIC = cell(1,nfactor);
    factor_norm = cell(1,nfactor);
    for j = 1:nfactor
        f = normalize(ishighthebetter(j)*facts{j}, 'method', 'norminv', 'weight', o.bmhd, 'GICS', option.normdata, 'level', option.normlevel);
        if isfield(option,'excludesector')
            if ~isnan(option.excludesector{j})                    
                sectormat = floor(fts2mat(o.gics)./1e6);
                f(ismember(sectormat,str2num(option.excludesector{j}))) = nan;
            end            
        end
%           for fs=1:numel(filterstr)            
%               level = 8-length(num2str(filterstr(fs)));
%               g = floor(gics_./10^level);
%               f(g==filterstr(fs)) = nan;                                
%           end                                         
        factor_norm{j} = f;
        facIC{j} = csrankcorr(factor_norm{j}, o.fwdret);
    end

    if strcmpi(option.wgtmethod, 'EW')
        facwgt = ones(1, nfactor);
    elseif strcmpi(option.wgtmethod, 'IC')
        facwgt = ftsmovavg([facIC{:}],option.window,1);
        facwgt = lagts(facwgt,1,nan);
    elseif strcmpi(option.wgtmethod, 'IR')
        facwgt = bsxfun(@rdivide, ftsmovavg([facIC{:}],option.window,1), ftsmovstd([facIC{:}],option.window,1));
        facwgt = lagts(facwgt,1,nan);
    elseif isnumeric(option.wgtmethod)
        assert(numel(option.wgtmethod) == nfactor, 'the size of input weight is not the same as the number of factors');
        facwgt = wgtmethod;
    end

    if numel(option.facgrp) > 1
        faccomp = cell(1,numel(option.facgrp));
        ICcomp = cell(1,numel(option.facgrp));
        for i = 1:numel(option.facgrp)
            faccomp{i} = ftswgtmean(facwgt(:,option.facgrp{i}), factor_norm{option.facgrp{i}});
            faccomp{i} = normalize(faccomp{i}, 'method', 'norminv', 'weight', o.bmhd, 'GICS', option.normdata, 'level', option.normlevel);
            ICcomp{i} = csrankcorr(faccomp{i}, o.fwdret);
        end
        if strcmpi(option.wgtmethod, 'EW')
            wgtcomp = ones(1, numel(option.facgrp));
        elseif strcmpi(option.wgtmethod, 'IC')
            wgtcomp = ftsmovavg([ICcomp{:}],option.window,1);
            wgtcomp = lagts(wgtcomp,1,nan);
        elseif strcmpi(option.wgtmethod, 'IR')
            wgtcomp = bsxfun(@rdivide, ftsmovavg([ICcomp{:}],option.window,1), ftsmovstd([ICcomp{:}],option.window,1));
            wgtcomp = lagts(wgtcomp,1,nan);
        end
        alpha = ftswgtmean(wgtcomp, faccomp{:});
    else
        alpha = ftswgtmean(facwgt, factor_norm{:});
    end

    alpha = normalize(alpha, 'method', 'norminv', 'weight', o.bmhd, 'GICS', option.normdata, 'level', option.normlevel);

    [LS, Long, Short] = factorPFRtn(alpha, o.fwdret, o.bmhd); 
    result.Alpha = alpha;
    result.IC = csrankcorr(alpha, o.fwdret);
    result.LS = LS;
    result.Long = Long;
    result.Short = Short;
    result.AC = csrankcorr(alpha, lagts(alpha,1,nan));
    result.TO = bsxfun(@rdivide, cssum(abs(alpha - lagts(alpha,1,nan))), cssum(abs(lagts(alpha,1,nan))));
end
