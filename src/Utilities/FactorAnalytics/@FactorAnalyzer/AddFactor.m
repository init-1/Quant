function o = AddFactor(o, facinfo, isprod)
    if nargin < 2
        isprod = 0; 
    end
    if ~isfield(facinfo,'ishigh')
        facstruct = LoadFactorInfo(facinfo.name,'HigherTheBetter',isprod);
        facinfo.ishigh = facstruct.HigherTheBetter';                
    end
    existingidx = ismember(facinfo.name, o.facinfo.name);
    facinfo.name(existingidx) = [];
    facinfo.ishigh(existingidx) = [];
    o.facinfo.name = reshape(o.facinfo.name, 1, numel(o.facinfo.name));
    facinfo.name = reshape(facinfo.name, 1, numel(facinfo.name));
    o.facinfo.name = [o.facinfo.name, facinfo.name];
    o.facinfo.ishigh = [o.facinfo.ishigh, facinfo.ishigh];

    startdate = datestr(o.bmhd.dates(1), 'yyyy-mm-dd');
    enddate = datestr(o.bmhd.dates(end), 'yyyy-mm-dd');
    secids = FieldId2QuantId(fieldnames(o.bmhd,1));
    if FactorAnalyzer.isFactorId(facinfo.name)
        factor = FactorAnalyzer.LoadFactor(secids, facinfo.name, startdate, enddate, isprod, o.freq, o.dateParam{:});
    else
        factor = FactorAnalyzer.RunFactorBT(facinfo.name, secids, startdate, enddate, o.freq, o.dateParam{:});
    end
    [factor{:}] = alignto(o.bmhd, factor{:});    
    o.factorts = reshape(o.factorts, 1, numel(o.factorts));
    factor = reshape(factor, 1, numel(factor));
    o.factorts = [o.factorts, factor];

end