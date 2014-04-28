function ftsArray = LoadRawItemPIT2(secIds, itemId, startDate, endDate, numQtrs, targetFreq)
    ftsArray = DB.LoadPIT(secIds, itemId, startDate, endDate, numQtrs);
    if nargin > 5
        [ftsArray{:}] = aligndates(ftsArray{:}, targetFreq);
    end
    ftsArray = cellfun(@(x){padfield(x,secIds,NaN,1)}, ftsArray);
end
