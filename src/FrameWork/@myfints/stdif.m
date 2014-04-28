function result = stdif(fts, dim, cond)
mystd = @(x,dim) nanstd(x, [], dim);
result = funif(fts, dim, cond, mystd, 'std');
