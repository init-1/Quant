function o = CalculateCorrMat(o, faclist)
    if ~exist('faclist', 'var')
        faclist = o.facinfo.name;
    end
    [~,loc] = ismember(faclist,o.facinfo.name);
    ishigh = o.facinfo.ishigh(loc);
    facdata = o.factorts(loc);
    nf = numel(faclist);
    cmat = zeros(nf,nf);
    flistpair = nchoosek(faclist,2);

    for i = 1:size(flistpair,1)
        [~,loc1] = ismember(flistpair{i,1},faclist);
        [~,loc2] = ismember(flistpair{i,2},faclist);
        series1 = facdata{loc1}.*ishigh(loc1);
        series2 = facdata{loc2}.*ishigh(loc2);            
        cs_corr = csrankcorr(series1,series2);
        cmat(loc1,loc2) = nanmean(cs_corr);
    end
    o.corrmat = cmat;
end