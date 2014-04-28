secIds     = {'0059MMM','0059MSFT'};
isLive     = 0;
startDate  = '2010-05-01';
endDate    = '2011-03-31';
targetFreq = 'M';
 
factor_BT = create(Book2Price, secIds, isLive, startDate, endDate, targetFreq);
