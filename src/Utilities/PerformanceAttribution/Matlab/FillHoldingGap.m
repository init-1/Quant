% this function fills up the gap in the input holding by using the input
% price
function newholding = FillHoldingGap(holding, price)

assert(isalignedfields(holding, price), 'the fields in the input fts are not aligned');

dates = union(holding.dates, price.dates);
[holding, price] = aligndates(holding, price, dates);

price = backfill(price, 21, 'entry');

shares = holding*10000./price; % scale up to avoid precision issue
shares = backfill(shares, inf, 'row'); 

newholding = shares.*price;
newholding = bsxfun(@rdivide, newholding, nansum(newholding,2));

end

