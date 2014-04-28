function result = sumif(fts, dim, cond)
% FUNCTION: sumif(fts, dim, condition)

result = funif(fts, dim, cond, @nansum, 'sum');
