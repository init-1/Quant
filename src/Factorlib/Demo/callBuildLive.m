secIds  = {'0059MMM','0059MSFT'};
isLive  = 1;
runDate = '2011-04-04';

factor_Live = create(Book2Price(), secIds, isLive, runDate);
